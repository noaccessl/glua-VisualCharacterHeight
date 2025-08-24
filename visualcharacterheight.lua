
--
-- Advanced settings
--
local VCH_OVERRIDE_DEFAULTS = true -- Should the script override default surface.CreateFont & surface.SetFont?

local g_pfnGetFont
--[[
	If you set VCH_OVERRIDE_DEFAULTS to false,
	then assumingly you have your own surface.GetFont
	and in that case set g_pfnGetFont to it.

	Or.

	Just provide the font-in-use to the surface.GetVisualCharacterHeight.
]]


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
local CreateFontEx
local SetFontEx

if ( VCH_OVERRIDE_DEFAULTS ) then

	surface.CreateFontEx = surface.CreateFontEx or surface.CreateFont
	surface.SetFontEx = surface.SetFontEx or surface.SetFont

	CreateFontEx = surface.CreateFontEx
	SetFontEx = surface.SetFontEx

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Override surface.CreateFont
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
if ( VCH_OVERRIDE_DEFAULTS ) then

	function surface.CreateFont( name, data )

		-- Clearing the font's cache so that it may be calculated properly later,
		-- just in case if the font is sized dynamically across the session
		VisualCharacterHeight_Uncache( name )

		return CreateFontEx( name, data )

	end

end

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Store the current font for later access
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local g_strCurrentTextFont

if ( VCH_OVERRIDE_DEFAULTS ) then

	g_strCurrentTextFont = 'DermaDefault'

	function surface.SetFont( font )

		g_strCurrentTextFont = font

		return SetFontEx( font )

	end

end


--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Cache
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
local VCHCache = {}

function VisualCharacterHeight_Uncache( specificfont )

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

local g_texVCH = GetRenderTargetEx(

	'_rt_VisualCharacterHeight',
	ScrW(), ScrH(),
	RT_SIZE_FULL_FRAME_BUFFER, MATERIAL_RT_DEPTH_NONE,
	2 + 256, 0,
	IMAGE_FORMAT_A8

)

--[[–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––
	Purpose: Works out the visual height of the provided character(-s)
–––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––––]]
function surface.GetVisualCharacterHeight( char, font )

	if ( not isstring( char ) ) then
		error( Format( 'bad argument #1 to \'GetVisualCharacterHeight\' (string expected, got %s)', type( char ) ) )
	end

	--
	-- Manage the font
	--
	if ( not VCH_OVERRIDE_DEFAULTS ) then

		if ( g_pfnGetFont ) then
			g_strCurrentTextFont = g_pfnGetFont()
		end

		if ( not font and not g_strCurrentTextFont ) then
			error( 'font to \'GetVisualCharacterHeight\' isn\'t provided or cannot be obtained' )
		end

		if ( font and ( g_strCurrentTextFont and g_strCurrentTextFont ~= font or true ) ) then
			surface.SetFont( font )
		elseif ( g_strCurrentTextFont ) then
			font = g_strCurrentTextFont
		end

	else

		if ( font and g_strCurrentTextFont ~= font ) then
			surface.SetFont( font )
		else
			font = g_strCurrentTextFont
		end

	end

	--
	-- Prepare a place in the cache
	--
	local vchcache_font = VCHCache[font]

	if ( not vchcache_font ) then

		vchcache_font = {}
		VCHCache[font] = vchcache_font

	else -- Return the stored if it exists

		local charmeasures = vchcache_font[char]

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
		-- surface.GetTextSize doesn't take into account tabs
		-- and/or a font may lack configuration regarding the tab character

	end

	local w, h = surface.GetTextSize( char )

	--
	-- The main process
	--
	local yTop
	local yBottom

	render.PushRenderTarget( g_texVCH )
	render.SetScissorRect( 0, 0, w, h, true )

		render.Clear( 255, 255, 255, 0 )

		surface.SetAlphaMultiplier( 1 )
		-- Just in case the overall alpha at the moment is zero

		-- Draw
		cam.Start2D()

			if ( string.find( char, '\n' ) ) then

				DrawText( char, font, 0, 0 )

			else

				surface.SetTextPos( 0, 0 )
				surface.SetTextColor( 255, 255, 255 )
				surface.DrawText( char )

			end

		cam.End2D()

		-- Dump the pixels
		render.CapturePixels()

		--
		-- Calculations
		--
		do

			local y, stop_y = -1, h - 1

			::find_top_vertical::
			y = y + 1

				local x, stop_x = -1, w - 1

				::find_top_horizontal::
				x = x + 1

					local _, _, _, alpha = ReadPixel( x, y )

					if ( alpha ~= 0 ) then

						yTop = y
						goto exit

					end

				if ( x ~= stop_x ) then goto find_top_horizontal end

			if ( y ~= stop_y ) then goto find_top_vertical end

			::exit::

		end

		do

			local y, stop_y = h - 1, 0

			::find_bottom_vertical::
			y = y - 1

				local x, stop_x = -1, w - 1

				::find_bottom_horizontal::
				x = x + 1

					local _, _, _, alpha = ReadPixel( x, y )

					if ( alpha ~= 0 ) then

						yBottom = y
						goto exit

					end

				if ( x ~= stop_x ) then goto find_bottom_horizontal end

			if ( y ~= stop_y ) then goto find_bottom_vertical end

			::exit::

		end

	render.SetScissorRect( 0, 0, 0, 0, false )
	render.PopRenderTarget()

	local visualheight = ( yBottom - yTop ) + 1
	local roofheight = yTop

	if ( not vchcache_font[char] ) then
		vchcache_font[char] = { visualheight = visualheight; roofheight = roofheight }
	end

	return visualheight, roofheight

end
