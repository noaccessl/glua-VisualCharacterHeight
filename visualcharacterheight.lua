--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Store the original functions
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
surface.CreateFontX	= surface.CreateFontX or surface.CreateFont
surface.SetFontX = surface.SetFontX or surface.SetFont

local CreateFontX = surface.CreateFontX
local SetFontX = surface.SetFontX


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Store the current font for later access
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local FONT_CURRENT = 'DermaDefault'

function surface.SetFont( font )

	FONT_CURRENT = font
	return SetFontX( font )

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Find the visual height of specific character(-s)
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
do

	--
	-- Globals, Utilities
	--
	local pairs = pairs

	local isstring = isstring

	local strfind	= string.find
	local DrawText	= draw.DrawText

	local ReadPixel = render.ReadPixel
	local MathMin	= function( a, b ) return ( a < b ) and a or b end
	local MathMax	= function( a, b ) return ( a > b ) and a or b end


	--
	-- Cache
	--
	local Cache = {}

	function surface.ClearVCHCache()

		for font in pairs( Cache ) do
			Cache[ font ] = nil
		end

	end

	function surface.CreateFont( name, data )

		-- Purge the font's cache so that it may be calculated properly later
		-- Because some fonts are made with "dynamic" sizes e.g. through ScreenScale( ... )
		Cache[ name ] = nil

		return CreateFontX( name, data )

	end

	--
	-- Main
	--
	local pTextureVCH = GetRenderTargetEx( '_rt_VisualCharacterHeight',

		1024,						-- width
		1024,						-- height

		RT_SIZE_LITERAL,			-- sizeMode
		MATERIAL_RT_DEPTH_NONE,		-- depthMode
		bit.bor( 2, 256 ),			-- textureFlags
		0,							-- rtFlags
		IMAGE_FORMAT_RGB888			-- imageFormat

	)

	function surface.GetVisualCharacterHeight( char, font )

		if ( not isstring( char ) ) then
			assert( false, Format( 'bad argument #1 to \'GetVisualCharacterHeight\' (string expected, got %s)', type( char ) ) )
		end

		--
		-- Manage the font
		--
		if ( font ) then
			surface.SetFont( font )
		else
			font = FONT_CURRENT
		end

		--
		-- Prepare place in cache
		--
		local CachedFont = Cache[ font ]

		if ( not CachedFont ) then

			Cache[ font ] = {}
			CachedFont = Cache[ font ]

		else

			--
			-- Return the stored if it exists
			--
			local data = CachedFont[ char ]

			if ( data ) then
				return data.Height, data.EmptySpace
			end

		end

		local w, h = surface.GetTextSize( char )

		--
		-- Just in case if something has set it to zero
		-- For example, this is called in some panel's paint, but the panel is fully transparent
		--
		surface.SetAlphaMultiplier( 1 )

		--
		-- Process the RT
		--
		render.PushRenderTarget( pTextureVCH )

			render.Clear( 0, 0, 0, 255 )

			--
			-- Draw the character(-s)
			--
			cam.Start2D()

				if ( strfind( char, '\n' ) ~= nil ) then
					DrawText( char, font, 0, 0, color_white )
				else

					surface.SetTextPos( 0, 0 )
					surface.SetTextColor( 255, 255, 255 )
					surface.DrawText( char )

				end

			cam.End2D()

			--
			-- Get access to the pixels
			--
			render.CapturePixels()

			--
			-- Calculate
			--
			local iStartY = h
			local iEndY = 0

			for y = 0, h - 1 do

				for x = 0, w - 1 do

					local r, g, b = ReadPixel( x, y )

					if ( r > 0 and g > 0 and b > 0 ) then

						iStartY = MathMin( iStartY, y )
						iEndY = MathMax( iEndY, y )

					end

				end

			end

		render.PopRenderTarget()

		--
		-- Find out the height and the empty space
		--
		iEndY = iEndY + 1

		local iHeight, iEmptySpace = MathMax( iEndY - iStartY, 1 ), iStartY

		--
		-- Store in the cache
		--
		if ( not CachedFont[ char ] ) then
			CachedFont[ char ] = { Height = iHeight; EmptySpace = iEmptySpace }
		end

		return iHeight, iEmptySpace

	end

end
