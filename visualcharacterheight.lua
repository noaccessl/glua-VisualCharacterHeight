surface.ex = surface.ex or {

	CreateFont = surface.CreateFont;
	SetFont = surface.SetFont

}

do

	local find = string.find
	local DrawText = draw.DrawText

	local ReadPixel = render.ReadPixel
	local min = math.min
	local max = math.max

	local cache = {}

	function surface.ClearVCHCache()
		cache = {}
	end

	local current = 'DermaDefault'

	function surface.SetFont( font )

		current = font
		return surface.ex.SetFont( font )

	end

	function surface.CreateFont( font, data )

		cache[font] = nil
		return surface.ex.CreateFont( font, data )

	end

	local rt = GetRenderTargetEx( 'vch', 1024, 1024, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 2, 0, IMAGE_FORMAT_BGR888 )

	function surface.GetVisualCharacterHeight( char, font )

		if font then
			surface.SetFont( font )
		else
			font = current
		end

		if not cache[font] then
			cache[font] = {}
		end

		local cached = cache[font][char]

		if cached then
			return cached.height, cached.emptySpace
		end

		char = char or 'ЁQ'
		local w, h = surface.GetTextSize( char )

		surface.SetAlphaMultiplier( 1 )

		render.PushRenderTarget( rt )

			render.Clear( 0, 0, 0, 255 )

			cam.Start2D()

				if find( char, '\n' ) ~= nil then
					DrawText( char, font, 0, 0, color_white )
				else

					surface.SetTextPos( 0, 0 )
					surface.SetTextColor( 255, 255, 255 )
					surface.DrawText( char )

				end

			cam.End2D()

			render.CapturePixels()

			local min_y = h
			local max_y = 0

			for y = 0, h - 1 do

				for x = 0, w - 1 do

					local r, g, b = ReadPixel( x, y )

					if r > 0 and g > 0 and b > 0 then

						min_y = min( min_y, y )
						max_y = max( max_y, y )

					end

				end

			end

		render.PopRenderTarget()

		max_y = max_y + 1

		local height, emptySpace = max( max_y - min_y, 1 ), min_y

		if not cache[font][char] then
			cache[font][char] = { height = height; emptySpace = emptySpace }
		end

		return height, emptySpace

	end

end
