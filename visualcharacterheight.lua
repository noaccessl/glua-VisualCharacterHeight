do

	local GetRenderTargetEx = GetRenderTargetEx
	local PushRenderTarget = render.PushRenderTarget
	local PopRenderTarget = render.PopRenderTarget
	local CapturePixels = render.CapturePixels
	local ReadPixel = render.ReadPixel

	local SetFont = surface.SetFont
	local GetTextSize = surface.GetTextSize
	local SetDrawColor = surface.SetDrawColor
	local DrawRect = surface.DrawRect
	local SetTextPos = surface.SetTextPos
	local SetTextColor = surface.SetTextColor
	local DrawText = surface.DrawText

	local Start2D = cam.Start2D
	local End2D = cam.End2D

	local min = math.min
	local max = math.max

	function surface.GetVisualCharacterHeight( char, font_optional )

		if font_optional then
			SetFont( font_optional )
		end

		char = char or 'ЁQ'
		local w, h = GetTextSize( char )

		local rt = GetRenderTargetEx( char, w, h, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 1, 0, IMAGE_FORMAT_DEFAULT )

		PushRenderTarget( rt )

			Start2D()

				SetDrawColor( color_black )
				DrawRect( 0, 0, w, h )

				SetTextPos( 0, 0 )
				SetTextColor( 255, 255, 255, 255 )
				DrawText( char )

			End2D()

			CapturePixels()

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

		PopRenderTarget()

		max_y = max_y + 1

		return max( max_y - min_y, 1 ), min_y

	end

end
