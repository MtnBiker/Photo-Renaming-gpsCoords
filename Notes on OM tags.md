Forget where this is from, but maybe Olympus.pm

Name => 'SpecialMode',
Notes => q{
	3 numbers: 1. Shooting mode: 0=Normal, 2=Fast, 3=Panorama;
	2. Sequence Number; 3. Panorama Direction: 1=Left-right,
	2=Right-left, 3=Bottom-Top, 4=Top-Bottom
	
Name => 'FocusMode',
	Writable => 'int16u',
	Count => -1,
	Notes => '1 or 2 values',
	PrintConv => [{
		0 => 'Single AF',
		1 => 'Sequential shooting AF',
		2 => 'Continuous AF',
		3 => 'Multi AF',
		4 => 'Face Detect', #11
		10 => 'MF',

		
0x600 => { #PH/4/22
		Name => 'DriveMode',
		Writable => 'int16u',
		Count => -1,
		Notes => '2, 3 or 5 numbers: 1. Mode, 2. Shot number, 3. Mode bits, 5. Shutter mode',
		PrintConv => q{
			my ($a,$b,$c,$d,$e) = split ' ',$val;
			if ($e) {
				$e = '; ' . ({ 2 => 'Anti-shock 0', 4 => 'Electronic shutter' }->{$e} || "Unknown ($e)");
			} else {
				$e = '';
			}
			return "Single Shot$e" unless $a;
			if ($a == 5 and defined $c) {
				$a = DecodeBits($c, { #6
					0 => 'AE',
					1 => 'WB',
					2 => 'FL',
					3 => 'MF',
					4 => 'ISO', #forum8906
					5 => 'AE Auto', #forum8906
					6 => 'Focus', #PH
				}) . ' Bracketing';
				$a =~ s/, /+/g;
			} else {
				my %a = (
					1 => 'Continuous Shooting',
					2 => 'Exposure Bracketing',
					3 => 'White Balance Bracketing',
					4 => 'Exposure+WB Bracketing', #6
					
	0x509 => { #6
	Name => 'SceneMode',
	Writable => 'int16u',
	PrintConvColumns => 2,
	PrintConv => {
		0 => 'Standard',
		6 => 'Auto', #6
		7 => 'Sport',
		8 => 'Portrait',
		9 => 'Landscape+Portrait',
		10 => 'Landscape',
		11 => 'Night Scene',
		12 => 'Self Portrait', #11
		13 => 'Panorama', #6
		14 => '2 in 1', #11
		15 => 'Movie', #11
		16 => 'Landscape+Portrait', #6
		17 => 'Night+Portrait',
		18 => 'Indoor', #11 (Party - PH)
		19 => 'Fireworks',
		20 => 'Sunset',
		21 => 'Beauty Skin', #PH
		22 => 'Macro',
		23 => 'Super Macro', #11
		24 => 'Food', #11
		25 => 'Documents',
		26 => 'Museum',
		27 => 'Shoot & Select', #11
		28 => 'Beach & Snow',
		29 => 'Self Protrait+Timer', #11
		30 => 'Candle',
		31 => 'Available Light', #11
		32 => 'Behind Glass', #11
		33 => 'My Mode', #11
		34 => 'Pet', #11
		35 => 'Underwater Wide1', #6
		36 => 'Underwater Macro', #6
		37 => 'Shoot & Select1', #11
		38 => 'Shoot & Select2', #11
		39 => 'High Key',
		40 => 'Digital Image Stabilization', #6
		41 => 'Auction', #11
		42 => 'Beach', #11
		43 => 'Snow', #11
		44 => 'Underwater Wide2', #6
		45 => 'Low Key', #6
		46 => 'Children', #6
		47 => 'Vivid', #11
		48 => 'Nature Macro', #6
		49 => 'Underwater Snapshot', #11
		50 => 'Shooting Guide', #11
		54 => 'Face Portrait', #11
		57 => 'Bulb', #11
		59 => 'Smile Shot', #11
		60 => 'Quick Shutter', #11
		63 => 'Slow Shutter', #11
		64 => 'Bird Watching', #11
		65 => 'Multiple Exposure', #11
		66 => 'e-Portrait', #11
		67 => 'Soft Background Shot', #11
		142 => 'Hand-held Starlight', #PH (SH-21)
		154 => 'HDR', #PH (XZ-2)
		197 => 'Panning', #forum11631 (EM5iii)
		203 => 'Light Trails', #forum11631 (EM5iii)
		204 => 'Backlight HDR', #forum11631 (EM5iii)
		205 => 'Silent', #forum11631 (EM5iii)
		206 => 'Multi Focus Shot', #forum11631 (EM5iii)
		
	0x301 => { #6
		Name => 'FocusMode',
		Writable => 'int16u',
		Count => -1,
		Notes => '1 or 2 values',
		PrintConv => [{
			0 => 'Single AF',
			1 => 'Sequential shooting AF',
			2 => 'Continuous AF',
			3 => 'Multi AF',
			4 => 'Face Detect', #11
			10 => 'MF',
		}, {
			0 => '(none)',
			BITMASK => { #11
				0 => 'S-AF',
				2 => 'C-AF',
				4 => 'MF',
				5 => 'Face Detect',
				6 => 'Imager AF',
				7 => 'Live View Magnification Frame',
				8 => 'AF sensor',
				9 => 'Starry Sky AF', #24
			},
		}],
	},
	0x302 => { #6
		Name => 'FocusProcess',
		Writable => 'int16u',
		Count => -1,
		Notes => '1 or 2 values',
		PrintConv => [{
			0 => 'AF Not Used',
			1 => 'AF Used',