/*
 todo:
 - out-of-range insert key
 - combine with existing insert key script
 
*/
macroScript InsertBezierKeyMS
	category:"Detachmode"
(

 global InsertBezierKey
 (
 	struct InsertBezierKeyStruct
 	(
		newKey = undefined,
		k1outTangent,
		k1outTangentLength,
		k2inTangent,
		k2inTangentLength,
		keys,
		u = 0.5,
		udiv,
		loopcounter = 0,
		
 		fn destroy = try(destroydialog InsertBezierKey.MainRollout ) catch(),
		
		fn tofloat framevalue =
		(
			((framevalue).ticks/(4800.0/frameRate))
		),

		fn insertKey track keepOldKeys:false attime:undefined = with redraw off 
		(
		
			if classof track != bezier_float then
				return()
			
			local keys = track.keys
			this.keys = keys
			local divCenter = ((this.udiv.x as float) + (this.udiv.y as float)) / 2.0
			local u 
			if attime == undefined then
				u = InsertBezierKey.u
			else
				u = divCenter

			
			local k1 = undefined
			local k2 = undefined
			for k in track.keys do
			(
				--// Wenn Curve breits Key an der stelle hat, dann überspringe diesen Track
				if (this.tofloat k.time) == attime then
					return()
				
				if (this.tofloat k.time) < attime then
					k1 = k
				
				if (this.tofloat k.time) >= attime AND k2 == undefined then
					k2 = k
				
			)
			
			local const = frameRate/(4800.0/frameRate)
			
			if NOT keepOldKeys then
			(
				InsertBezierKey.k1outTangent =  k1.outTangent 
				InsertBezierKey.k1outTangentLength =  k1.outTangentLength 
				InsertBezierKey.k2inTangent = k2.inTangent
				InsertBezierKey.k2inTangentLength =  k2.inTangentLength 
			)

			local delta = tofloat k2.time-k1.time

			local alph = atan2 this.k1outTangent  const

			--p1 
			local p1y = k1.value
			local p1x = (tofloat k1.time) 

			--p2
			local p2y = k1.value +  (tan alph) * (this.k1outTangentLength *delta)
			local p2x = (tofloat k1.time) + (this.k1outTangentLength *delta)

			--p12
			local p12y = p1y + u*(p2y-p1y)
			local p12x = p1x + u*(p2x-p1x)

			--p3
			local alph2 = atan2 this.k2inTangent const

			local p3y = k2.value +  (tan alph2) * (this.k2inTangentLength *delta)
			local p3x = (tofloat k2.time) - (this.k2inTangentLength *delta)

			--p4 
			local p4y = k2.value
			local p4x = (tofloat k2.time)

			--p34
			local p34y = p3y + u*(p4y-p3y) 
			local p34x = p3x + u*(p4x-p3x)

			--p23
			local p23y = p2y + u*(p3y-p2y)
			local p23x = p2x + u*(p3x-p2x)

			--// Final values
			--p123
			local p123y = p12y + u*(p23y-p12y)
			local p123x = p12x + u*(p23x-p12x) 

			--p234
			local p234y = p23y + u*(p34y-p23y)
			local p234x = p23x + u*(p34x-p23x) 


			local pNewY = p123y + u*(p234y-p123y) 
			local pNewX = p123x + u*(p234x-p123x)
			
			
			--// Approximation
			if attime != undefined then
			(
				if this.loopcounter == 0 then 
				(
-- 					print pNewX
-- 					print InsertBezierKey.u
-- 					print "----"
				)
				this.loopcounter = this.loopcounter +1
				if this.loopcounter < 15 then 
				(
					--// Here is recursion
-- 					print "++++"
-- 					print pNewX
-- 					print InsertBezierKey.udiv
-- 					print "++++"
									
					if (pNewX > attime) then
					(
						InsertBezierKey.udiv = [InsertBezierKey.udiv.x, divCenter]
						this.insertKey track attime:attime
						return()
					)
					
					if (pNewX < attime) then
					(
						InsertBezierKey.udiv = [divCenter,InsertBezierKey.udiv.y]
						this.insertKey track attime:attime
						return()
					)
					
				)
				else
				(
-- 					print pNewX

				)				

				
				pNewX = attime

			)
			
			


			--// todo
			
			if InsertBezierKey.newKey == undefined then with undo "insert Bezier Key" on
				InsertBezierKey.newKey = addNewKey track pNewX-- add a key at frame 0
			else
			(
				InsertBezierKey.newKey.time = pNewX
				InsertBezierKey.newKey.value = pNewY
			)
			
			with undo off
			(


				--// adjust new key tangents
				local a = p123x-pnewx
				local b = p1x
				local c = pNewX
				local d = p123y-pnewy

				InsertBezierKey.newKey.inTangentType = #custom-- make inTangent custom
				InsertBezierKey.newKey.inTangentLength = a/(b - c)
				InsertBezierKey.newKey.inTangent = -d*const/a

				InsertBezierKey.newKey.outTangentType = #custom-- make inTangent custom

				local a = p234x-pnewx
				local b = p4x
				local c = pNewX
				local d = p234y-pnewy

				InsertBezierKey.newKey.outTangentLength = a / (b-c)
				InsertBezierKey.newKey.outTangent = d *const/a

				--// adjust left key tangents
				local a = p12x-p1x
				local b = pnewx
				local c = p1x
				local d = p12y-p1y

				k1.outTangentType = #custom
				k1.outTangentLength = a / (b-c)
				k1.outTangent = d *const/a

				--// adjust right key tangents
				local a = p34x-p4x
				local b = pnewx
				local c = p4x
				local d = p34y-p4y

				local k3 = undefined
				for k in track.keys do
				(				
					if (this.tofloat k.time) > attime AND k3 == undefined then
						k3= k
					
				)


				k3.inTangentType = #custom-- make inTangent custom
				k3.inTangentLength = a/(b - c)
				k3.inTangent = -d*const/a

			)
			
		),
		
		fn main = 
		(
			local attime = InsertBezierKey.tofloat currenttime
			
			for i = 1 to trackviews.currentTrackView.numSelTracks() do
			(
				local track = trackviews.currentTrackView.getSelected i
				InsertBezierKey.udiv = [.0,1.]
				InsertBezierKey.loopcounter = 0
				InsertBezierKey.newKey = undefined
				InsertBezierKey.insertKey track attime:attime
			)
		)


 
 	)
 	InsertBezierKey = InsertBezierKeyStruct()
 	ok
 )
 
InsertBezierKey.main()
)
