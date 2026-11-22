local _, ns = ...

ns.Utils = {}

function ns.Utils.GetXY(position)
    if not position then
        return nil
    end

    if position.GetXY then
        return position:GetXY()
    end

    return position.x, position.y
end
