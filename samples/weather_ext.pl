#!/usr/bin/perl
# $Revision: 1.1 $
use strict;
use Weather::Com::Finder;
use Data::Dumper;

$| = 1;

# you have to fill in your ids from weather.com here
my $PartnerId  = '';
my $LicenseKey = '';

# you can preset units of messures here
# (m for metric (default), s for us)
my $units = 'm';

# if you need a proxy... maybe with authentication
my $Proxy      = '';
my $Proxy_User = '';
my $Proxy_Pass = '';

# debugging on/off
my $debugmode = 0;
if ( $ARGV[0] && ( $ARGV[0] eq "-d" ) ) {
	warn "Debug mode turned on.\n";
	$debugmode = 1;
}

my %weatherargs = (
					'partner_id' => $PartnerId,
					'license'    => $LicenseKey,
					'units'      => $units,
					'debug'      => $debugmode,
					'proxy'      => $Proxy,
					'proxy_user' => $Proxy_User,
					'proxy_pass' => $Proxy_Pass,
);

my $weather_finder = Weather::Com::Finder->new(%weatherargs);

# print greeting
print "\nWelcome to Uncle Tom's weather station...\n";
print "\nPlease enter a location name to look for, e.g\n";
print "'Heidelberg' or 'Seattle, WA', or 'Munich, Germany'\n\n";

# define prompt
my $prompt = '$> ';
print $prompt;

while ( chomp( my $input = <STDIN> ) ) {

	# don't want any empty input
	unless ( $input =~ /\S+/ ) {
		print $prompt;
		next;
	}

	# and if the user wants to exit...
	last if ( $input =~ /^end|quit|exit$/ );

	# search for matching locations
	my $locations = $weather_finder->find($input);

	# if $weather_finder->find() returned 0, we haven't found anything...
	unless ($locations) {
		print "No weather found for location '$input'\n";
		print $prompt;
		next;
	}

	# if we found anything we'll print it out...
	print "\nFound weather data for " . @{$locations} . " locations:\n\n";

	# define all units of measure (we can use the units of the first location
	# because they should all be equal...)
	my $uodist   = $locations->[0]->units()->distance();
	my $uoprecip = $locations->[0]->units()->precipitation();
	my $uopress  = $locations->[0]->units()->pressure();
	my $uotemp   = $locations->[0]->units()->temperature();
	my $uospeed  = $locations->[0]->units()->speed();

	foreach my $location ( @{$locations} ) {

		# print a nice heading underlined by '===='
		my $heading = "This is the data for " . $location->name() . "\n";
		print $heading;
		print "=" x length($heading), "\n";

		# print location data
		print " * this city is located at: ", $location->latitude(), "deg N, ",
		  $location->longitude(), "deg E\n";
		print " * local time is ",               $location->localtime(), "\n";
		print " * sunrise will be/has been at ", $location->sunrise(),   "\n";
		print " * sunset (am/pm) will be/has been at ",
		  $location->sunset_ampm(), "\n";
		print " * timezone is GMT + ", $location->timezone(), "hour(s)\n";

		# current conditions
		print "\nCurrent Conditions:\n";
		print " * current conditions are ",
		  $location->current_conditions()->description(), ".\n";
		print " * visibilty is about ",
		  $location->current_conditions()->visibility(), " $uodist.\n";
		print " * and the temperature is ",
		  $location->current_conditions()->temperature(), "deg $uotemp.\n";
		print " * the current windchill is ",
		  $location->current_conditions()->windchill(), "deg $uotemp.\n";
		print " * the humidity is ",
		  $location->current_conditions()->humidity(), "\%.\n";
		print " * the dewpoint is ",
		  $location->current_conditions()->dewpoint(), "deg $uotemp.\n";

		# all about wind
		print " * wind speed is ",
		  $location->current_conditions()->wind()->speed(), " $uospeed.\n";    
		print " * wind comes from ",
		  $location->current_conditions()->wind()->direction_long(), ".\n";
		print "   ... in short ",
		  $location->current_conditions()->wind()->direction_short(), ".\n";
		print "   ... in degrees ",
		  $location->current_conditions()->wind()->direction_degrees(), ".\n";
		print "   ... max. gust ",
		  $location->current_conditions()->wind()->maximum_gust(), " $uospeed.\n";

		# all about uv index
		print " * uv index is ",
		  $location->current_conditions()->uv_index()->index(), ".\n";
		print "   ... that is ",
		  $location->current_conditions()->uv_index()->description(), ".\n";

		# all about barometric pressure
		print " * air pressure is ",
		  $location->current_conditions()->pressure()->pressure(), " $uopress.\n";
		print "   ... tendency ",
		  $location->current_conditions()->pressure()->tendency(), ".\n";

		print "\n";
	}

	# last but not least print the next prompt
	print $prompt;
}

__END__

=pod

=head1 NAME

weather.pl - Sample script to show the usage of the I<Weather::Simple>
module

=head1 SYNOPSIS

  #> ./weather.pl [-d]
  
  Welcome to Uncle Tom's weather station...
  
  Please enter a location name to look for, e.g
  'Heidelberg' or 'Seattle, WA', or 'Munich, Germany'
  
  Type 'end' to exit.
  
  $>

=head1 DESCRIPTION

**IMPORTANT** You first have to register at I<weather.com> to get a
partner id and a license key for free. Please visit their web site
L<http://www.weather.com/services/xmloap.html>. Then edit this script
and fill in the data into the corresponding variables at the top of 
the script.

The sample script I<weather.pl> asks you for a location name - either 
a city or a 'city, region' or 'city, country' combination. It then uses 
the I<Weather::Simple> module to get the current weather conditions 
for this location(s).

If no location matching your input is found, a "no locations found" 
message is printed out.

Else, the number of locations found is printed followed by nicely
formatted weather data for each location.

The command line parameter '-d' enables debugging mode (which is
enabling debugging within all used packages (Weather::Simple,
Weather::Cached, Weather::Com).

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Thomas Schnuecker

This script is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut