ExGeohash
=========

This library offers a basic set of methods to work with geohash numbers.

-Functions:

	# This method calculates the geohash of the longitude and latitude using precision bits
	# @param latitude, longitude, GPS position to be converted
	# @return num, number representing the geohash
	- encode(latitude, longitude, precision)

	This method returns the original latitude and longitude from one geohash
	@param geohash, geohash number to be converted
	@param precision, precision to be used
	@return {{latitude, longitude}, {min_lat, max_lat, min_lon, max_lon}}, GPS coordinates decoded from the geohash with the bounding box around that point
	- decode(geohash, precision)
	
	This method returns the minimum necessary bits to get the desired radius
	@param radius, desired radius in meters
	@return number of required bits
	- get_precision_bits(radius)
	
	This method returns the 8 neighboors of the current point
	@param geohash, geohash of the current point
	@param precision, number of bits of the geohash
	@return list of geohashes of the desired neighboors
	- get_neighboors(geohash, precision) 

	
	This method returns the number with the new desired precision
	@param number, number to be converted
	@param current_precision, number of precision bits of the current number
	@param new_precision, desired precision. new_precision should be > current_precision
	- fix_precision(number, current_precision, new_precision)
	
	This method returns the planar distances between two gps points
	@param lat1, lon1 gps point1
	@param lat2, lon2 gps point 20
	@return distance in meters between the two points
	- get_gps_distance(lat1,lon1, lat2, lon2)
