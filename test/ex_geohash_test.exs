defmodule ExGeohashTest do
  use ExUnit.Case  
  
  @first_value  %{"lat": 4.62715, "lon": -74.08122, distance_to_a: 0}
  @locations  [
    %{"lat": 4.62715, "lon": -74.08122, distance_to_a: 0}, #Centro
    %{"lat": 4.63192, "lon": -74.08798, distance_to_a: 917}, #Punto B a
    %{"lat": 4.62088, "lon": -74.08617, distance_to_a: 885}, #Punto C a
    %{"lat": 4.62678, "lon": -74.07304, distance_to_a: 909}, #Punto D a
    %{"lat": 4.62943, "lon": -74.09527, distance_to_a: 1579},  #Punto E a
    %{"lat": 4.61044, "lon": -74.09364, distance_to_a: 2305}, #Punto F a
    %{"lat": 4.61224, "lon": -74.07476, distance_to_a: 1798}, #Punto G a
    %{"lat": 4.63756, "lon": -74.06901, distance_to_a: 1778}, #Punto H a
    %{"lat": 4.63996, "lon": -74.10300, distance_to_a: 2801}, #Punto I a
    %{"lat": 4.61985, "lon": -74.10171, distance_to_a: 2413}, #Punto J a
    %{"lat": 4.64680, "lon": -74.07982, distance_to_a: 2178}, #Punto K a
    %{"lat": 4.62114, "lon": -74.06755, distance_to_a: 1656}, #Punto L a
    %{"lat": 4.63029, "lon": -74.11785, distance_to_a: 4079} #Punto M a
]

  test "Encode Testing" do  
	assert 209629790 == ExGeohash.encode(40.23908988,44.03103014,28)
	assert 425318738886645 == ExGeohash.encode(4.72,-72.15,50)
	assert 1997550 == ExGeohash.encode(-51.79345874,-140.66799993,26)
	assert 15134305348 == ExGeohash.encode(13.0665548,102.2172017,34)
	assert 229607259801302 == ExGeohash.encode(54.360848,13.6592917,48)
	assert 662751237716772 == ExGeohash.encode(-54.3786706,-70.0893997,52)
	assert 15134305350 != ExGeohash.encode(13.0665548,102.2172017,34)
  end
  
  test "Decode Testing" do  
	#The error depends on the precision
	{{lat, lon},{min_lat, max_lat, min_lon, max_lon}} = ExGeohash.decode(209629790, 28)
	assert abs(lat - (40.23908988)) < 0.01
	assert abs(lon - (44.03103014)) < 0.01
	
	{{lat, lon},{min_lat, max_lat, min_lon, max_lon}} = ExGeohash.decode(425318738886645, 50)
	assert abs(lat - (4.72)) < 0.00001
	assert abs(lon - (-72.15)) < 0.00001
	
	{{lat, lon},{min_lat, max_lat, min_lon, max_lon}} = ExGeohash.decode(1997550, 26)
	assert abs(lat - (-51.79345874)) < 0.03
	assert abs(lon - (-140.66799993)) < 0.03
	
	{{lat, lon},{min_lat, max_lat, min_lon, max_lon}} = ExGeohash.decode(15134305348, 34)
	assert abs(lat - (13.0665548)) < 0.001
	assert abs(lon - (102.2172017)) < 0.001

  end
  
  test "GPS distance Test" do
	
	for value <- @locations, do: assert get_error( value[:distance_to_a], ExGeohash.get_gps_distance(value[:lat], value[:lon],@first_value[:lat],@first_value[:lon])) < 0.1

  end
  
  def get_error(real, calculated) do
	abs(real - calculated)/(real+1)
  end
  
  test "Precision test" do

	assert 26 == ExGeohash.get_precision_bits(3000)
	assert 36 == ExGeohash.get_precision_bits(100)
	assert 24 == ExGeohash.get_precision_bits(6000)
	assert 22 == ExGeohash.get_precision_bits(15000)
  end
end
