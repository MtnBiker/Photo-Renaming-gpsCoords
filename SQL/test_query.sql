﻿SELECT * FROM indonesia ORDER BY ST_Distance(ST_GeomFromText('POINT(-5.077258 119.546587)', 4326), geom) ASC LIMIT 3