local _, ns = ...

local COLOR_BUCKET_COUNT = 32

local function resetTexture(_, texture)
    texture:Hide()
    texture:ClearAllPoints()
end

local function buildColorLUT()
    local lut = {}
    local stops = ns.Config.colorStops

    for bucket = 0, COLOR_BUCKET_COUNT - 1 do
        local intensity = bucket / (COLOR_BUCKET_COUNT - 1)
        local red, green, blue

        for index = 1, #stops - 1 do
            local first, second = stops[index], stops[index + 1]
            if intensity <= second.position then
                local range = second.position - first.position
                local localIntensity = range > 0
                    and (intensity - first.position) / range
                    or 0
                red = first.color[1] + (second.color[1] - first.color[1]) * localIntensity
                green = first.color[2] + (second.color[2] - first.color[2]) * localIntensity
                blue = first.color[3] + (second.color[3] - first.color[3]) * localIntensity
                break
            end
        end

        if not red then
            local last = stops[#stops].color
            red, green, blue = last[1], last[2], last[3]
        end

        lut[bucket] = {
            red = red,
            green = green,
            blue = blue,
            alpha = ns.Config.minAlpha
                + (ns.Config.maxAlpha - ns.Config.minAlpha) * intensity,
        }
    end

    return lut
end

local function buildBucketThresholds()
    local thresholds = {}
    local minimumCount = ns.Config.intensityMinCount
    local maximumCount = ns.Config.intensityMaxCount
    local minimumLog = math.log(minimumCount)
    local logRange = math.log(maximumCount) - minimumLog

    for bucket = 1, COLOR_BUCKET_COUNT - 1 do
        local intensity = (bucket - 0.5) / (COLOR_BUCKET_COUNT - 1)
        thresholds[bucket] = math.exp(minimumLog + logRange * intensity)
    end

    return thresholds
end

local COLOR_LUT = buildColorLUT()
local BUCKET_THRESHOLDS = buildBucketThresholds()

local function getCellCount(rawCount)
    if type(rawCount) == "table" then
        return tonumber(rawCount.count) or 0
    end
    return tonumber(rawCount) or 0
end

local function getColorBucket(count)
    if count <= ns.Config.intensityMinCount then
        return 0
    elseif count >= ns.Config.intensityMaxCount then
        return COLOR_BUCKET_COUNT - 1
    end

    local low, high = 1, COLOR_BUCKET_COUNT - 1
    local bucket = 0
    while low <= high do
        local middle = math.floor((low + high) / 2)
        if count >= BUCKET_THRESHOLDS[middle] then
            bucket = middle
            low = middle + 1
        else
            high = middle - 1
        end
    end

    return bucket
end

local function buildRuns(cells)
    local width = ns.Config.gridWidth
    local rows = {}
    local positiveCellCount = 0
    local bucketedCellCount = 0
    local firstRawType
    local firstRawValue

    for cellIndex, rawCount in pairs(cells) do
        if not firstRawType then
            firstRawType = type(rawCount)
            if firstRawType == "table" then
                local fields = {}
                for key, value in pairs(rawCount) do
                    fields[#fields + 1] = tostring(key) .. "=" .. tostring(value)
                    if #fields >= 3 then
                        break
                    end
                end
                firstRawValue = table.concat(fields, ",")
            else
                firstRawValue = tostring(rawCount)
            end
        end
        local count = getCellCount(rawCount)
        if count > 0 then
            positiveCellCount = positiveCellCount + 1
            local bucket = getColorBucket(count)
            if bucket ~= nil then
                bucketedCellCount = bucketedCellCount + 1
                local row = math.floor(cellIndex / width)
                local column = cellIndex - (row * width)
                local rowBuckets = rows[row]
                if not rowBuckets then
                    rowBuckets = {}
                    rows[row] = rowBuckets
                end
                rowBuckets[column] = bucket
            end
        end
    end

    local runs = {}
    for row, rowBuckets in pairs(rows) do
        local column = 0
        while column < width do
            local bucket = rowBuckets[column]
            if bucket ~= nil then
                local startColumn = column
                repeat
                    column = column + 1
                until column >= width or rowBuckets[column] ~= bucket

                runs[#runs + 1] = {
                    row = row,
                    column = startColumn,
                    length = column - startColumn,
                    bucket = bucket,
                }
            else
                column = column + 1
            end
        end
    end

    if ns.HeatmapRenderer then
        ns.HeatmapRenderer.lastBuildState = {
            positiveCellCount = positiveCellCount,
            bucketedCellCount = bucketedCellCount,
            runCount = #runs,
            firstRawType = firstRawType or "none",
            firstRawValue = firstRawValue or "none",
        }
    end

    return runs
end

-- Create the mixin at file scope so the XML template is ready before the
-- provider acquires its first pin.
ExplorerFootprintMapPinMixin = CreateFromMixins(MapCanvasPinMixin)

function ExplorerFootprintMapPinMixin:OnLoad()
    -- Jade Forest and other zone maps can have detail layers above the
    -- default pin frame level. Use Blizzard's registered area-POI level so
    -- the heatmap remains visible across the complete map canvas.
    self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")

    self.pool = CreateTexturePool(self, "ARTWORK", nil, nil, resetTexture)
    self:EnableMouse(false)
end

function ExplorerFootprintMapPinMixin:OnAcquired(data)
    self.runs = data and data.runs or {}
    self:SetAlpha(data and data.opacity or 1)
    self:Layout()
end

function ExplorerFootprintMapPinMixin:OnReleased()
    self.pool:ReleaseAll()
    self.runs = nil
    self:SetAlpha(0)
end

function ExplorerFootprintMapPinMixin:Layout()
    local map = self:GetMap()
    if not map then
        return
    end

    local canvas = map.GetCanvas and map:GetCanvas()
    if not canvas then
        return
    end

    -- This pin is a full-canvas layer, so anchor it directly to the map
    -- canvas. That avoids relying on normalized pin sizing/positioning and
    -- keeps the texture layer aligned during map pan and zoom.
    self:ClearAllPoints()
    self:SetAllPoints(canvas)
    local canvasWidth, canvasHeight = canvas:GetSize()
    canvasWidth = math.max(1, canvasWidth)
    canvasHeight = math.max(1, canvasHeight)

    self.pool:ReleaseAll()
    local cellWidth = canvasWidth / ns.Config.gridWidth
    local cellHeight = canvasHeight / ns.Config.gridHeight

    for _, run in ipairs(self.runs or {}) do
        local color = COLOR_LUT[run.bucket]
        local texture = self.pool:Acquire()
        texture:SetColorTexture(color.red, color.green, color.blue, color.alpha)
        texture:ClearAllPoints()
        texture:SetPoint(
            "TOPLEFT",
            self,
            "TOPLEFT",
            run.column * cellWidth,
            -run.row * cellHeight
        )
        texture:SetSize(run.length * cellWidth, cellHeight)
        texture:Show()
    end
end

function ExplorerFootprintMapPinMixin:OnCanvasSizeChanged()
    self:Layout()
end

function ExplorerFootprintMapPinMixin:OnCanvasScaleChanged()
    self:Layout()
end

ns.HeatmapRenderer = {
}

function ns.HeatmapRenderer:BuildRuns(cells)
    return buildRuns(cells)
end

function ns.HeatmapRenderer:Refresh()
    if ns.MapProvider then
        ns.MapProvider:RequestRefresh(true)
    end
end
