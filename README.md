# glua-VisualCharacterHeight
Finds visual height of a character(-s). May be very helpful when positioning text by height. Supports newlines.

## Comparison between `surface.GetTextSize` and `surface.GetVisualCharacterHeight`
![image](https://github.com/noaccessl/glua-VisualCharacterHeight/assets/54954576/f81035df-2f00-41b5-9551-6ffe0afbafad)
```lua
local font = 'DermaLarge'
local char = 'a'
local visH, emptySpace = surface.GetVisualCharacterHeight( char, font )

hook.Add( 'HUDPaint', '', function()

	surface.SetFont( font )
	local w, h = surface.GetTextSize( char )

	local x = ScrW() * 0.5 - w * 0.5 - 5
	local y = ScrH() * 0.5

	surface.SetDrawColor( 255, 180, 180 )
	surface.DrawRect( x, y, w, h )

	draw.SimpleText( char, font, x, y, color_black )

	x = ScrW() * 0.5 + 5 + w * 0.5

	surface.SetDrawColor( 180, 255, 180 )
	surface.DrawRect( x, y, w, visH )

	y = y - emptySpace

	draw.SimpleText( char, font, x, y, color_black )

end )
```
Also, works with newlines

![image](https://github.com/noaccessl/glua-VisualCharacterHeight/assets/54954576/b2318692-b2b2-4ddc-a464-b26337cdab09)
```lua
local font = 'DermaLarge'
local char = 'a\nb'
local visH, emptySpace = surface.GetVisualCharacterHeight( char, font )

hook.Add( 'HUDPaint', '', function()

	surface.SetFont( font )
	local w, h = surface.GetTextSize( char )

	local x = ScrW() * 0.5 - w * 0.5 - 5
	local y = ScrH() * 0.5

	surface.SetDrawColor( 255, 180, 180 )
	surface.DrawRect( x, y, w, h )

	draw.DrawText( char, font, x, y, color_black )

	x = ScrW() * 0.5 + 5 + w * 0.5

	surface.SetDrawColor( 180, 255, 180 )
	surface.DrawRect( x, y, w, visH )

	y = y - emptySpace

	draw.DrawText( char, font, x, y, color_black )

end )
```