package gamelib;

import gamelib.TileSheetAtlased;

typedef TileIndex = 
{
	tilesheet: Int, 
	tile: Int
}

class TileSheetCollection
{
	var sheets : Array<TileSheetAtlased>;
	var cur_idx : Int;

	public var current(get,null) : TileSheetAtlased;

	public function new()
	{
		sheets = new Array<TileSheetAtlased>();
	}

	public function destroy()
	{
		sheets = null;
	}

	public function get_current() : TileSheetAtlased
	{
		if (sheets.length == 0) return null;

		return sheets[cur_idx];
	}

	public function sheet_id_from_texture(img:phoenix.Texture) : Int
	{
		var i = 0;
		for (s in sheets)
		{
			if (s.image == img) return i;
			i++;
		}

		return -1;
	}

	public function get_sheet(id:Int) : TileSheetAtlased
	{
		if (id >= 0 && id < sheets.length) return sheets[id];

		return null;
	}

	public function get_index_for_sprite(s:luxe.Sprite) : TileIndex
	{
		var ts_id = sheet_id_from_texture(s.texture);

		if (ts_id != -1)
		{
			return { tilesheet: ts_id, tile: sheets[ts_id].get_tile_id_from_rect(s.uv) }
		}

		return null;
	}

	public function get_tile_for_sprite(s:luxe.Sprite) : TileData
	{
		var tilesheet = sheet_id_from_texture(s.texture);

		return sheets[tilesheet].get_tile_from_rect(s.uv);
	}

	public function set_index(tilesheet:Int, index:Int)
	{
		cur_idx = tilesheet;
		current.set_index(index);
	}

	public function set_sheet_ofs(ofs:Int) : TileSheetAtlased
	{
		cur_idx += ofs;
		if (cur_idx < 0) cur_idx = sheets.length - 1;
		if (cur_idx >= sheets.length) cur_idx = 0;

		return current;
	}

	public function select_group(grp:String) : Bool
	{
		if (sheets.length == 0) return false;

		var idx = (cur_idx + 1) % sheets.length;

		//NB! A bit scary - won't work if cur_idx is -1 (but I don't think it will happen. I always presume 0 so it crashes instead)
		while (idx != cur_idx)
		{
			if (sheets[idx].has_group(grp))
			{
				cur_idx = idx;
				break;
			}

			idx = (idx + 1) % sheets.length;
		}

		// default behavior is select/unselect at current
		return current.select_group(grp);
	}

	public function add(sheet:TileSheetAtlased) : TileSheetAtlased
	{
		// replace sheet based on name property
		var existing_idx = -1;
		for (s in sheets)
		{
			if (s.name == sheet.name) existing_idx = s.index;
		}

		if (existing_idx != -1)
		{
			sheets[existing_idx].destroy();
			sheet.index = existing_idx;
			sheets[existing_idx] = sheet;
		}
		else
		{
			sheet.index = sheets.length;
			sheets.push(sheet);

			if (sheets.length == 1) cur_idx = 0;
		}

		return sheet;
	}

	public static function from_json_data(data:Array<TileSheetAtlasedSerialize>) : TileSheetCollection
	{
		var ret = new TileSheetCollection();

		if (data != null)
		{
			for (ts in data)
			{
				var sheet = TileSheetAtlased.from_json_data(ts);
				ret.add(sheet);
			}
		}

		return ret;
	}

	public function to_json_data() : Array<TileSheetAtlasedSerialize>
	{
		var ret = new Array<TileSheetAtlasedSerialize>();

		for (s in sheets)
		{
			ret.push(s.to_json_data());
		}

		return ret;
	}
}