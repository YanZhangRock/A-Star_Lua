P = 1 -- passable
B = 0 -- blocked
g_map = {
    { P, P, P, P, P, P, P, P },
    { P, P, P, P, B, P, P, P },
    { P, P, P, P, B, P, P, P },
    { P, P, P, P, B, P, P, P },
    { P, P, P, P, P, P, P, P },
    { P, P, P, P, P, P, P, P },
}
COST1 = 10 -- vertical & horizontal
COST2 = 14 -- diagonal
g_start_pos = { 3, 3 }
g_end_pos = { 7, 3 }

g_open_list = {}
g_close_list = {}
g_round = 1

function LOG( _fmt, ... )
    return print( "[LOG] " .. string.format( _fmt, ... ) )
end
function ERR( _fmt, ... )
    return print( "[ERR] " .. string.format( _fmt, ... ) )
end

function get_scoreH( _p )
    return ( ( math.abs( _p[1] - g_end_pos[1] ) 
    + math.abs( _p[2] - g_end_pos[2] ) ) * COST1 )
end

function get_scoreG( _parent, _pos )
    local p0 = _parent.pos
    local dX = math.abs( p0[1] - _pos[1] )
    local dY = math.abs( p0[2] - _pos[2] )
    if ( dX == 1 and dY == 0 ) or ( dX == 0 and dY == 1 ) then
        return COST1 + _parent.scoreG
    elseif dX == 1 and dY == 1 then
        return COST2 + _parent.scoreG
    else
        ERR( "(get_scoreG) invalid distance, dX: %d, dY: %d", dX, dY )
        return 0
    end
end

function create_node( _pos, _parent )
    local node = {
        pos = _pos, 
        parent = _parent,
        scoreH = 0,
        scoreG = 0,
    }
    if _parent then
        node.scoreH = get_scoreH( _pos )
        node.scoreG = get_scoreG( _parent, _pos )
    end
    return node
end

function is_cross_corner( _ori_pos, _pos )
    local x1, y1 = _ori_pos[1], _ori_pos[2]
    local x2, y2 = _pos[1], _pos[2]
    local dX = math.abs( x1 - x2 )
    local dY = math.abs( y1 - y2 )
    if dX == 1 and dY == 1 then
        if ( g_map[y1][x2] ~= P ) or 
            ( g_map[y2][x1] ~= P ) then
            return true 
        end
    end
    return false
end

function is_valid_pos( _ori_pos, _pos )
    local x, y = _pos[1], _pos[2]
    if _ori_pos[1] == x and _ori_pos[2] == y then
        return false
    end
    if not g_map[y] or not g_map[y][x] then
        return false
    end
    if g_map[y][x] ~= P then
        return false
    end
    if is_cross_corner( _ori_pos, _pos ) then
        return false
    end
    return true
end

function check_on_list( _list, _p )
    for _, node in ipairs( _list ) do
        if node.pos[1] == _p[1] and node.pos[2] == _p[2] then
            return node 
        end
    end
end

function sort_by_scoreF( t1, t2 )
    return ( t1.scoreH + t1.scoreG ) < ( t2.scoreH + t2.scoreG )
end

function update_node( _node, _parent )
    if is_cross_corner( _parent.pos, _node.pos ) then return end
    local G = get_scoreG( _parent, _node.pos )
    if G >= _node.scoreG then return end
    _node.parent = _parent
    _node.scoreG = G
end

function create_trace()
    g_open_list, g_close_list = {}, {}
    local start_node = create_node( g_start_pos )
    table.insert( g_open_list, start_node )

    local dest_node = nil
    g_round = 1
    while true do
        local cur_node = table.remove( g_open_list, 1 )
        table.insert( g_close_list, cur_node )
        if cur_node.pos[1] == g_end_pos[1] and cur_node.pos[2] == g_end_pos[2] then
            dest_node = cur_node
            break
        end
        for x = -1, 1 do
            for y = -1, 1 do
                local pos = { cur_node.pos[1] + x, cur_node.pos[2] + y }
                if is_valid_pos( cur_node.pos, pos ) then
                    local node = check_on_list( g_open_list, pos ) 
                    if node then
                        update_node( node, cur_node )
                    else
                        local new_node = create_node( pos, cur_node )
                        table.insert( g_open_list, new_node )
                    end
                end
            end
        end
        if not next( g_open_list ) then
            break
        end
        table.sort( g_open_list, sort_by_scoreF )
        g_round = g_round + 1
    end
    if not dest_node then return end
    local node = dest_node
    local trace = {}
    while node ~= start_node do
        table.insert( trace, 1, node )
        node = node.parent
    end
    table.insert( trace, 1, start_node )
    return trace
end

function main()
    local trace = create_trace()
    if not trace then
        LOG( "(main) no trace found!" )
        return
    end
    for i, n in ipairs( trace ) do
        LOG( "trace: %d, pos: { %d, %d }, score: { %d, %d }", i, n.pos[1], n.pos[2], n.scoreG, n.scoreH )
    end
end

main()
