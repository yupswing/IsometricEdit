import luxe.Vector;
import luxe.Rectangle;

import phoenix.Texture;

using RectangleUtils;

typedef TileData = {
    rect: Rectangle,
    graph: Graph
};

typedef TileSheetAtlasedSerialize = {
    image: String,
    atlas: Array<TileDataSerialize>,
    groups: Array<GroupSerialize>
};

typedef GroupSerialize = { 
    k: String, 
    v: Array<Int> 
};

typedef TileDataSerialize = {
    graph: Dynamic,
    rect: Array<Float>
};

class TileSheetAtlased
{
	public var image : Texture;
    public var atlas : Array<TileData>;

    var groups : Map<String,Array<Int>>;
    var group_path : String;
    var group_cur_idx : Int = 0;
    var group_cycle_idx : Int = 0;

    var atlas_pos : Int = 0;

    public function new()
    {
    	atlas = new Array<TileData>();
        groups = new Map<String,Array<Int>>();
    }

    public inline function get_current_path() : String
    {
        return group_path;
    }

    public function to_json_data() : TileSheetAtlasedSerialize
    {
        var t_atlas = new Array<TileDataSerialize>();

        for (a in atlas)
        {
            var t_g = null;

            if (a.graph != null)
            {
                t_g = a.graph.to_json_data(); 
            }

            t_atlas.push({ rect: a.rect.to_array(), graph: t_g });
        }

        var t_groups = new Array<GroupSerialize>();
        for (k in groups.keys())
        {
            t_groups.push({ k: k, v: groups[k] }); 
        }

        return { image: image.asset.id, atlas: t_atlas, groups: t_groups };
    }

    public static function from_json() : TileSheetAtlased
    {
        return null;
    }

    public function add_idx_to_group(grp:String, idx:Int, ?toggle:Bool = false) : Bool
    {
        if (idx < 0 || idx >= atlas.length)
        {
            return false;
        }

        var a = groups.get(grp);
        if (a != null)
        {
            if (a.indexOf(idx) == -1)
            {
                a.push(idx);
                return true;
            }
            else
            {
                if (toggle)
                {
                    a.remove(idx);
                }

                return false;
            }
        }
        else
        {
            a = new Array<Int>();
            a.push(idx);
            groups.set(grp, a);

            return true; 
        }
    }

    function get_current_group() : Array<Int>
    {
        if (group_path == null)
        {
            return null;
        }

        var k = get_current_path();
        var a = groups.get(k);

        return a;
    }

    public function get_groups_for_idx(idx:Int) : Array<String>
    {
        var ret : Array<String> = null;

        for (k in groups.keys())
        {
            if (groups.get(k).indexOf(idx) != -1)
            {
                if (ret == null)
                {
                    ret = new Array<String>();
                }

                ret.push(k);
            }
        }

        return ret;
    }

    public function get_group(grp:String) : Array<Int>
    {
        return groups.get(grp);
    }

    public function set_group_index_ofs(offset:Int) : Int
    {
        if (group_path == null)
        {
            no_group();
            return set_index_ofs(offset);
        }

        var a = get_current_group();
        trace('current group array = $a, try to go $offset');

        if (a == null)
        {
            no_group();
            return set_index_ofs(offset);
        }

        group_cycle_idx += offset;

        if (group_cycle_idx >= a.length)
        {
            group_cycle_idx = 0;
        }
        else if (group_cycle_idx < 0)
        {
            group_cycle_idx = a.length - 1;
        }

        atlas_pos = a[group_cycle_idx];

        Luxe.events.queue('TileSheetAtlased.TileId', atlas_pos);

        return atlas_pos;
    }

    public function select_group(grp:String)
    {
        if (grp == null || !groups.exists(grp))
        {
            no_group();
            return;
        }

        group_path = grp;
        group_cycle_idx = 0;

        trace('try select group path = $group_path');

        set_group_index_ofs(0);

        Luxe.events.queue('TileSheetAtlased.GroupId', get_current_path());
    }

    public function no_group()
    {
        group_path = null;

        Luxe.events.queue('TileSheetAtlased.GroupId', '-');
    }

    public inline function get_tile_idx(pos:Vector, ?scale:Vector = null) : Int
    {
        var atlas_pos = -1;

        for (i in 0...atlas.length)
        {
            var rect = atlas[i].rect;

            if (scale != null)
            {
                rect = rect.clone();

                rect.x *= scale.x;
                rect.y *= scale.y;
                rect.w *= scale.x;
                rect.h *= scale.y;
            }

            if (rect.point_inside(pos))
            {
                atlas_pos = i;
                break;
            }
        }

        return atlas_pos;
    }

    public function get_tile_from_rect(rect:Rectangle)
    {
        for (i in 0...atlas.length)
        {
            if (atlas[i].rect.equal(rect))
            {
                return i;
            }
        }

        return -1;
    }

    public function set_index_ofs(idx:Int)
    {
        if (idx == 0) return atlas_pos;

        var len =  atlas.length;

        if (len == 0) return atlas_pos;

        atlas_pos += idx;

        if (atlas_pos >= len) atlas_pos = 0;
        if (atlas_pos < 0) atlas_pos = len - 1;

        Luxe.events.queue('TileSheetAtlased.TileId', atlas_pos);

        return atlas_pos;
    }

    public function set_index(idx:Int)
    {
    	if (idx >= 0 && idx < atlas.length)
    	{
            no_group(); 

    		atlas_pos = idx;

            Luxe.events.queue('TileSheetAtlased.TileId', atlas_pos);
    	}
    }

    public function get_current() : Rectangle
    {
    	if (atlas_pos >= 0 && atlas_pos < atlas.length)
    	{
    		return atlas[atlas_pos].rect;
    	}

    	return null;
    }
}