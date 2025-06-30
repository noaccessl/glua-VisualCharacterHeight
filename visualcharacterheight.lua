
--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Prepare
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
--
-- Functions & libraries
--
local isstring = isstring
local surface = surface
local render = render
local ReadPixel = render.ReadPixel
local cam = cam
local string = string
local DrawText = draw.DrawText


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Store the former functions
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
surface.CreateFontEx = surface.CreateFontEx or surface.CreateFont
surface.SetFontEx = surface.SetFontEx or surface.SetFont

local CreateFontEx = surface.CreateFontEx
local SetFontEx = surface.SetFontEx

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Override surface.CreateFont
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function surface.CreateFont( name, data )

	-- Clearing the font's cache so that it may be calculated properly later,
	-- just in case if the font is sized dynamically across the session
	surface.ClearVCHCache( name )

	return CreateFontEx( name, data )

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Store the current font for later access
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local g_strCurrentTextFont = 'DermaDefault'

function surface.SetFont( font )

	g_strCurrentTextFont = font

	return SetFontEx( font )

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Cache
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local VCHCache = {}

function surface.ClearVCHCache( specificfont )

	if ( specificfont ) then
		VCHCache[specificfont] = nil
	else
		for font in next, VCHCache do VCHCache[font] = nil end
	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	The common render target
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local IMAGE_FORMAT_A8 = 8

local g_rt_VCH = GetRenderTargetEx(

	'_rt_VisualCharacterHeight',
	2048, 2048,
	RT_SIZE_NO_CHANGE, MATERIAL_RT_DEPTH_NONE,
	2 + 256, 0,
	IMAGE_FORMAT_A8

)

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Works out the visual height of the provided character(-s)
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function surface.GetVisualCharacterHeight( char, font )

	if ( not isstring( char ) ) then
		assert( false, Format( 'bad argument #1 to \'GetVisualCharacterHeight\' (string expected, got %s)', type( char ) ) )
	end

	--
	-- Manage the font
	--
	if ( font and font ~= g_strCurrentTextFont ) then
		surface.SetFont( font )
	else
		font = g_strCurrentTextFont
	end

	--
	-- Prepare a place in the cache
	--
	local FontCache = VCHCache[font]

	if ( not FontCache ) then

		FontCache = {}
		VCHCache[font] = FontCache

	else -- Return the stored if it exists

		local charmeasures = FontCache[char]

		if ( charmeasures ) then
			return charmeasures.visualheight, charmeasures.roofheight
		end

	end

	--
	-- Work out the operating area
	--
	if ( string.find( char, '\t' ) ) then

		local tabWidth = 8
		char = string.gsub( char, '\t', string.rep( ' ', tabWidth ) )

	end

	local w, h = surface.GetTextSize( char )

	-- Just in case the function is called where/when the overall alpha is zero at the frame
	surface.SetAlphaMultiplier( 1 )

	--
	-- The main process
	--
	local iStartY
	local iEndY

	do

		render.PushRenderTarget( g_rt_VCH )
		render.SetScissorRect( 0, 0, w, h, true )

			render.Clear( 255, 255, 255, 0 )

			-- Draw
			cam.Start2D()

				if ( string.find( char, '\n' ) ) then
					DrawText( char, font, 0, 0, color_white )
				else

					surface.SetTextPos( 0, 0 )
					surface.SetTextColor( 255, 255, 255 )
					surface.DrawText( char )

				end

			cam.End2D()

			-- Access the pixels
			render.CapturePixels()

			--
			-- Calculations
			--
			do

				local y, stop_y = -1, h - 1

				::find_start_1::
				y = y + 1

					local x, stop_x = -1, w - 1

					::find_start_2::
					x = x + 1

						local _, _, _, alpha = ReadPixel( x, y )

						if ( alpha ~= 0 ) then

							iStartY = y
							goto exit

						end

					if ( x ~= stop_x ) then goto find_start_2 end

				if ( y ~= stop_y ) then goto find_start_1 end

				::exit::

			end

			do

				local y, stop_y = h - 1, 0

				::find_end_1::
				y = y - 1

					local x, stop_x = -1, w - 1

					::find_end_2::
					x = x + 1

						local _, _, _, alpha = ReadPixel( x, y )

						if ( alpha ~= 0 ) then

							iEndY = y
							goto exit

						end

					if ( x ~= stop_x ) then goto find_end_2 end

				if ( y ~= stop_y ) then goto find_end_1 end

				::exit::

			end

		render.SetScissorRect( 0, 0, 0, 0, false )
		render.PopRenderTarget()

	end

	local visualheight = ( iEndY - iStartY ) + 1
	local roofheight = iStartY

	if ( not FontCache[char] ) then
		FontCache[char] = { visualheight = visualheight; roofheight = roofheight }
	end

	return visualheight, roofheight

end
