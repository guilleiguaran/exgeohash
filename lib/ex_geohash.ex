defmodule ExGeohash do
	
	@precision_table [{52, 0.5971},{50, 1.1943},{48, 2.3889},{46, 4.7774},{44, 9.5547},{42, 19.1095},
	{40, 38.2189},{38, 76.4378},{36, 152.8757},{34, 305.751},{32, 611.5028},{30, 1223.0056},{28, 2446.0112},
	{26, 4892.0224 },{24, 9784.0449},{22, 19568.0898},{20, 39136.1797},{18, 78272.35938},{16, 156544.7188},
	{14, 313089.4375},{12, 626178.875},{10, 1252357.75},{8, 2504715.5},{6, 5009431},{4, 10018863}]
	
	@earth_radius 6371000
	
	@default_precision 52
	
	#-------------------------------------------------------------------------------------
	# Public Functions
	#-------------------------------------------------------------------------------------
	
	@doc """
	# This method calculates the geohash of the longitude and latitude using precision bits
	# @param latitude, longitude, GPS position to be converted
	# @return num, number representing the geohash
	"""
	def encode(latitude, longitude, precision) do
		try do
			{:ok, bits} = encode_recursive({:latitude, latitude, -90, 90}, {:longitude, longitude, -180, 180}, precision)
			<<num::size(precision)>> = bits
			num
		rescue
			e -> "Format error"
		end	
	end
	
	@doc """
	# This method returns the original latitude and longitude from one geohash
	# @param geohash, geohash number to be converted
	# @param precision, precision to be used
	# @return {{latitude, longitude}, {min_lat, max_lat, min_lon, max_lon}}, GPS coordinates decoded from the geohash with the bounding box around that point
	"""
	def decode(geohash, precision) do
		try do
			{:ok, {latitude, longitude},{min_lat, max_lat, min_lon, max_lon}} = decode_recursive(geohash,{:latitude, -90, 90},{:longitude, -180, 180}, precision)
			{{latitude, longitude}, {min_lat, max_lat, min_lon, max_lon}}
		rescue
			e -> "Format error"
		end	
	end

	@doc """
		This method returns the minimum necessary bits to get the desired radius
		@param radius, desired radius in meters
		@return number of required bits
	"""
	def get_precision_bits(radius) do
		bits = get_precision_bits_from_table(@precision_table, radius)
		bits
	end
	
	@doc """
		This method returns the 8 neighboors of the current point
		@param geohash, geohash of the current point
		@param precision, number of bits of the geohash
		@return list of geohashes of the desired neighboors
	"""
	def get_neighboors(geohash, precision) do
		neighboors = []
		
		neighboors = [get_neighboors_direction(geohash, precision, {1,0})] ++ neighboors	
		neighboors = [get_neighboors_direction(geohash, precision, {1,1})] ++ neighboors		
		neighboors = [get_neighboors_direction(geohash, precision, {1,-1})] ++ neighboors
		neighboors = [get_neighboors_direction(geohash, precision, {-1,0})] ++ neighboors
		neighboors = [get_neighboors_direction(geohash, precision, {-1,1})] ++ neighboors
		neighboors = [get_neighboors_direction(geohash, precision, {-1,-1})] ++ neighboors
		neighboors = [get_neighboors_direction(geohash, precision, {0,1})] ++ neighboors
		neighboors = [get_neighboors_direction(geohash, precision, {0,-1})] ++ neighboors
		
		neighboors
	end
	
	@doc """
		This method returns the number with the new desired precision
		@param number, number to be converted
		@param current_precision, number of precision bits of the current number
		@param new_precision, desired precision. new_precision should be > current_precision
	"""
	def fix_precision(number, current_precision, new_precision) do	
		bits = <<number::size(current_precision)>>
		diff = new_precision - current_precision
		<<number::size(new_precision)>> = <<bits::bitstring,0::size(diff)>>
		number
	end
	
	@doc """
		This method returns the planar distances between two gps points
		@param lat1, lon1 gps point1
		@param lat2, lon2 gps point 20
		@return distance in meters between the two points
	"""
	def get_gps_distance(lat1,lon1, lat2, lon2) do
		lat1r = deg_rad(lat1)
		lon1r = deg_rad(lon1)
		lat2r = deg_rad(lat2)
		lon2r = deg_rad(lon2)
		u = :math.sin((lat2r - lat1r)/2)
		v = :math.sin((lon2r - lon1r)/2)
		distance = 2.0 * @earth_radius * :math.asin(:math.sqrt(u * u + :math.cos(lat1r) * :math.cos(lat2r) * v * v))			
		distance
	end
	
	
	#--------------------------------------------------------------------------------------
	# Private Functions
	#--------------------------------------------------------------------------------------
	
	defp deg_rad(number) do
		number * :math.pi / 180
	end
	
	defp get_precision_bits_from_table([current| rest], radius) do
		{bits, precision} = current
		cond do
			precision >= radius -> bits
			precision < radius -> get_precision_bits_from_table(rest, radius)
		end
	end
	
	@doc """
	# This method uses the geaohash algorithm to convert the lat_current and lon_current to the corresponding geohash
	# @param lat_current, lon_current GPS position to be converted
	# @param lat_min_limit, lat_max_limit current border limits of latitude
	# @param lon_min_limit, lon_max_limit current border limits of longitude
	# @param current_precision number of precision bits to be used. It must be a multiply of 2
	# @return {:ok, response} where response is the final bitstring with the geohash
	"""
	defp encode_recursive({:latitude, lat_current, lat_min_limit, lat_max_limit}, {:longitude, lon_current, lon_min_limit, lon_max_limit}, current_precision) do
		lat_mid = (lat_max_limit + lat_min_limit)/2
		lon_mid = (lon_max_limit + lon_min_limit)/2

		{new_bit_lon, new_lon_min_limit, new_lon_max_limit} = get_new_limits(lon_current, lon_min_limit, lon_mid, lon_max_limit)
		
		{new_bit_lat, new_lat_min_limit, new_lat_max_limit} = get_new_limits(lat_current, lat_min_limit, lat_mid, lat_max_limit)
		response = << new_bit_lon::bitstring, new_bit_lat::bitstring >>
			
		cond do
			current_precision > 2 and rem(current_precision, 2) == 0 ->
				{:ok, lower_response} = encode_recursive({:latitude, lat_current, new_lat_min_limit, new_lat_max_limit}, {:longitude, lon_current, new_lon_min_limit, new_lon_max_limit}, current_precision-2)
				response = << response::bitstring, lower_response::bitstring >>
				{:ok, response}
			rem(current_precision, 2) == 1 -> {:error, 0}
			true ->	{:ok, response}
		end			

	end
	
	@doc """
	# This method returns the new limits according to the mid value
	# @param current, current value to be evaluated
	# @param min, max current border limits
	# @param mid, middle of the range
	# @return {response, min, max} response is a bitstring 1 if current is above mid, 0 otherwise. Min and max are the new limits.
	"""
	defp get_new_limits(current, min, mid, max) do
		cond do
			current > mid -> {<<1::size(1)>>, mid, max}
			current <= mid -> {<<0::size(1)>>, min, mid}
		end		
	end
	
	
	@doc """
	# This method converts the geohash into the corresponding latitude, longitude and their bounding box
	# @param bits_array, current geohash to process
	# @param lat_min_limit, lat_max_limit current border limits of latitude
	# @param lon_min_limit, lon_max_limit current border limits of longitude
	# @param precision number of precision bits to be used. It must be a multiply of 2
	# @return {:ok, {latitude, longitude},{min_lat, max_lat, min_lon, max_lon}} latitude, longitud, and the bounding box
	"""
	defp decode_recursive(bits_array, {:latitude, lat_min_limit, lat_max_limit}, {:longitude, lon_min_limit, lon_max_limit}, precision) do
		lat_mid = (lat_max_limit + lat_min_limit)/2
		lon_mid = (lon_max_limit + lon_min_limit)/2
		
		new_precision = precision - 2
		<<lon_bit::size(1), lat_bit::size(1), rest::size(new_precision)>> = <<bits_array::size(precision)>>

		{new_lon_min_limit, new_lon_max_limit} = get_new_decode_limits(lon_bit, lon_min_limit, lon_mid, lon_max_limit)
		
		{new_lat_min_limit, new_lat_max_limit} = get_new_decode_limits(lat_bit, lat_min_limit, lat_mid, lat_max_limit)
		
		cond do
			rem(precision, 2)==0 and precision > 2 ->
				decode_recursive(rest,{:latitude, new_lat_min_limit, new_lat_max_limit}, {:longitude, new_lon_min_limit, new_lon_max_limit}, precision-2)
			precision == 2 ->
				{:ok, {(new_lat_min_limit+new_lat_max_limit)/2 , (new_lon_min_limit+new_lon_max_limit)/2}, {new_lat_min_limit, new_lat_max_limit, new_lon_min_limit, new_lon_max_limit}}
			rem(precision, 2) == 1 ->
				{:error, {0,0}, {0,0,0,0}}
		end		
	end
	
	defp get_new_decode_limits(bit, min, mid, max) do
		cond do
			bit==1 -> {mid, max}
			bit==0 -> {min, mid}
		end		
	end
	
	@doc """
		This method returns the neighboor at the direction
		@param geohash, geohash of the current point
		@param precision, number of bits of the geohash
		@param direction, array with the normalized direction. {1,0} N, {-1,0} S, {0,1} E, {0,-1} W
		@return geohash of the desired neighboor
	"""
	def get_neighboors_direction(geohash, precision, direction) do
		{:ok, {lat, lon},{min_lat, max_lat, min_lon, max_lon}} = decode_recursive(geohash,{:latitude, -90, 90},{:longitude, -180, 180}, precision)
		
		dif_lat =  abs(max_lat - min_lat)
		dif_lon = abs(max_lon - min_lon)
		
		{neigh_lat, neigh_lon} = {lat+elem(direction,0)*dif_lat , lon+elem(direction,1)*dif_lon}
		{:ok, bits} = encode_recursive({:latitude, neigh_lat, -90, 90}, {:longitude, neigh_lon, -180, 180}, precision)
		<<num::size(precision)>> = bits
		num
	end
	
end