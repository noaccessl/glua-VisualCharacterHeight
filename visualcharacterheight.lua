do

	local SetFont = surface.SetFont

	local find = string.find
	local DrawText = draw.DrawText

	local ReadPixel = render.ReadPixel
	local min = math.min
	local max = math.max

	local font = 'TargetID'
	local cache = setmetatable( {}, { __mode = 'k' } )

	timer.Create( 'surface.ClearVCHCache', 60, 0, function()
		for i = 1, #cache do cache[i] = nil end
	end )

	function surface.SetFont( _font )

		font = _font
		return SetFont(_font )

	end

	function surface.GetVisualCharacterHeight( char, font_optional )

		if font_optional then
			surface.SetFont( font_optional )
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

		local rt = GetRenderTargetEx( char, w, h, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 1, 0, IMAGE_FORMAT_DEFAULT )

		render.PushRenderTarget( rt )

			cam.Start2D()

				surface.SetDrawColor( color_black )
				surface.DrawRect( 0, 0, w, h )

				if find( char, '\n' ) ~= nil then
					DrawText( char, font, 0, 0, color_white )
				else

					surface.SetTextPos( 0, 0 )
					surface.SetTextColor( 255, 255, 255, 255 )
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