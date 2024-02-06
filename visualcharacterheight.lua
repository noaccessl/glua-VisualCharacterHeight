--[[---------------------------------------------------------------------------
	Store original functions
---------------------------------------------------------------------------]]
surface.ex = surface.ex or {

	CreateFont	= surface.CreateFont;
	SetFont		= surface.SetFont

}

--[[---------------------------------------------------------------------------
	Visual character height
---------------------------------------------------------------------------]]
do

	local StringFind = string.find
	local DrawText	 = draw.DrawText

	local ReadPixel = render.ReadPixel
	local MathMin	= math.min
	local MathMax	= math.max

	local Cache = {}

	function surface.ClearVCHCache()
		Cache = {}
	end

	local UsingFont = 'DermaDefault'

	function surface.SetFont( font )

		UsingFont = font
		return surface.ex.SetFont( font )

	end

	function surface.CreateFont( font, data )

		Cache[ font ] = nil
		return surface.ex.CreateFont( font, data )

	end

	local RT = GetRenderTargetEx( 'vch', 1024, 1024, RT_SIZE_LITERAL, MATERIAL_RT_DEPTH_NONE, 2, 0, IMAGE_FORMAT_BGR888 )

	function surface.GetVisualCharacterHeight( char, font )

		--
		-- Prepare font
		--
		if font then
			surface.SetFont( font )
		else
			font = UsingFont
		end

		--
		-- Prepare place in cache
		--
		if not Cache[ font ] then
			Cache[ font ] = {}
		end

		--
		-- Return stored if it exists
		--
		local stored = Cache[ font ][ char ]

		if stored then
			return stored.Height, stored.EmptySpace
		end

		char = char or 'ЁQ'

		local w, h = surface.GetTextSize( char )

		--
		-- For proper calculations
		--
		surface.SetAlphaMultiplier( 1 )

		render.PushRenderTarget( RT )

			render.Clear( 0, 0, 0, 255 )

			cam.Start2D()

				if StringFind( char, '\n' ) ~= nil then
					DrawText( char, font, 0, 0, color_white )
				else

					surface.SetTextPos( 0, 0 )
					surface.SetTextColor( 255, 255, 255 )
					surface.DrawText( char )

				end

			cam.End2D()

			render.CapturePixels()

			local StartPos = h
			local EndPos = 0

			for y = 0, h - 1 do

				for x = 0, w - 1 do

					local r, g, b = ReadPixel( x, y )

					if r > 0 and g > 0 and b > 0 then

						StartPos = MathMin( StartPos, y )
						EndPos = MathMax( EndPos, y )

					end

				end

			end

		render.PopRenderTarget()

		EndPos = EndPos + 1

		local Height, EmptySpace = MathMax( EndPos - StartPos, 1 ), StartPos

		if not Cache[ font ][ char ] then
			Cache[ font ][ char ] = { Height = Height; EmptySpace = EmptySpace }
		end

		return Height, EmptySpace

	end

end
