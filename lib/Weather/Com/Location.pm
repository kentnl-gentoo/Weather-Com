package Weather::Com::Location;

use 5.006;
use strict;
use warnings;
use Time::Local;
use Weather::Com::Cached;
use Weather::Com::Units;
use Weather::Com::CurrentConditions;

#use Weather::Com::Forecast;
use base "Weather::Com::Cached";

our $VERSION = sprintf "%d.%03d", q$Revision: 1.2 $ =~ /(\d+)/g;

#------------------------------------------------------------------------
# Constructor
#------------------------------------------------------------------------
sub new {
	my $proto      = shift;
	my $class      = ref($proto) || $proto;
	my %parameters = ();

	# parameters provided by new method
	if ( ref( $_[0] ) eq "HASH" ) {
		%parameters = %{ $_[0] };
	} else {
		%parameters = @_;
	}

	unless ( $parameters{location_id} ) {
		die "You need to provide a location id!\n";
	}

	# set some parameters to sensible values for a pure location
	# object
	$parameters{current}  = 0;
	$parameters{forecast} = 0;
	$parameters{links}    = 0;

	# creating the SUPER instance
	my $self = $class->SUPER::new( \%parameters );

	$self->{ID}    = $parameters{location_id};
	$self->{ARGS}  = \%parameters;
	$self->{DEBUG} = $parameters{debug};

	# the weather data will be initialized when the first call on
	# data is performed
	$self->{HEAD}       = undef;
	$self->{WEATHER}    = undef;
	$self->{CONDITIONS} = undef;
	$self->{FORECAST}   = undef;

	# last update will be used to trigger automatic refresh of
	# location data
	$self->{LSUP} = time();

	bless( $self, $class );

	return $self;
}    # end new()

#------------------------------------------------------------------------
# refresh weather data
#------------------------------------------------------------------------
# this calls refresh if weather data is not initialized yet
sub refresh {
	my $self = shift;
	unless ( $self->{WEATHER} ) {
		$self->_debug("Refreshing weather information...");
		$self->{WEATHER} = $self->get_weather( $self->{ID} );
		$self->{LSUP}    = time();
	}
	return 1;
}

#------------------------------------------------------------------------
# access location data
#------------------------------------------------------------------------
sub id {
	my $self = shift;
	return $self->{ID};
}

sub name {
	my $self = shift;
	$self->refresh();
	return $self->{WEATHER}->{loc}->{dnam};
}

sub units {
	my $self = shift;
	$self->refresh();

	unless ( $self->{HEAD} ) {
		$self->{HEAD} = Weather::Com::Units->new();
	}
	$self->{HEAD}->update( $self->{WEATHER}->{head} );	
	return $self->{HEAD};
}

sub timezone {
	my $self = shift;
	$self->refresh();
	return $self->{WEATHER}->{loc}->{zone};
}

sub latitude {
	my $self = shift;
	$self->refresh();
	return $self->{WEATHER}->{loc}->{lat};
}

sub longitude {
	my $self = shift;
	$self->refresh();
	return $self->{WEATHER}->{loc}->{lon};
}

sub sunrise {
	my $self = shift;
	$self->refresh();
	$self->_update();
	my $sunr = $self->{WEATHER}->{loc}->{sunr};
	return &Weather::Com::Base::_simple2twentyfour($sunr);
}

sub sunrise_ampm {
	my $self = shift;
	$self->refresh();
	$self->_update();
	return $self->{WEATHER}->{loc}->{sunr};
}

sub sunset {
	my $self = shift;
	$self->refresh();
	$self->_update();
	my $suns = $self->{WEATHER}->{loc}->{suns};
	return &Weather::Com::Base::_simple2twentyfour($suns);
}

sub sunset_ampm {
	my $self = shift;
	$self->refresh();
	$self->_update();
	return $self->{WEATHER}->{loc}->{suns};
}

# localtime will be calculated because it does not make
# any sense to used a cached time as current local time of
# some location
sub localtime {
	my $self = shift;
	my @gm   = gmtime( $self->_local_epoc( time() ) );
	return "$gm[2]:$gm[1]";
}

sub localtime_ampm {
	my $self = shift;
	my @gm   = gmtime( $self->_local_epoc( time() ) );
	my $ampm = "AM";

	# and we have to find out weather we wanna print AM or PM
	# and then substract 12 hours if it's afternoon
	if ( $gm[2] > 12 ) {
		$gm[2] -= 12;
		$ampm = "PM";
	}

	return "$gm[2]:$gm[1] $ampm";
}

sub current_conditions {
	my $self = shift;
	unless ( $self->{CONDITIONS} ) {
		$self->{CONDITIONS} =
		  Weather::Com::CurrentConditions->new( $self->{ARGS} );
	}
	return $self->{CONDITIONS};
}

sub forecast {
	my $self = shift;
	unless ( $self->{FORECAST} ) {
		$self->{FORECAST} = Weather::Com::Forecast->new( $self->{ARGS} );
	}
	return $self->{FORECAST};
}

#------------------------------------------------------------------------
# internal methods go here
#------------------------------------------------------------------------
sub _update {
	my $self = shift;

	# idea for check if now is one or more days after last update:
	# 1. transform last update to 00:00:00 of last updated date in
	#    local time of location
	# 2. get 00:00:00 of today in local time of location
	# If both in epoc are equal, no update is needed, else we'll get
	# the new location information.
	my @lsup = gmtime( $self->_local_epoc( $self->{LSUP} ) );
	$lsup[0] = 0;
	$lsup[1] = 0;
	$lsup[2] = 0;
	my $local_epoc_lsup = timelocal(@lsup);

	$self->{LSUP} = time();
	my @now = gmtime( $self->_local_epoc( $self->{LSUP} ) );
	$now[0] = 0;
	$now[1] = 0;
	$now[2] = 0;
	my $local_epoc_now = timelocal(@now);

	if ( $local_epoc_now > $local_epoc_lsup ) {
		$self->_debug("refreshing location cache...\n");
		$self->refresh();
	}
}

sub _local_epoc {
	my $self = shift;
	my $time = shift;
	return ( $time + ( $self->timezone() * 3600 ) );
}

1;

__END__

=pod

=head1 NAME

Weather::Com::Location - class representing one location and its weather

=head1 SYNOPSIS

  #!/usr/bin/perl -w
  use Weather::Com::Finder;

  # you have to fill in your ids from weather.com here
  my $PartnerId  = 'somepartnerid';
  my $LicenseKey = 'mylicense';

  my %weatherargs = (
	'partner_id' => $PartnerId,
	'license'    => $LicenseKey,
  );

  my $finder = Weather::Com::Finder->new(%weatherargs);
  
  # if you want an array of locations:
  my @locations = $finder->find('Heidelberg');
  
  # or if you prefer an arrayref:
  my $locations = $finder->find('Heidelberg');
  
  foreach my $location (@locations) {
    print "Found weather for city: ", $location->name(), "\n";
    print "The city is located at: ", $location->latitude(), "deg N, ",
		  $location->longitude(), "deg E\n";
	print "Local time is ", $location->localtime(), "\n";
	print "Sunrise will be/has been at ", $location->sunrise(), "\n";
    
  }

=head1 DESCRIPTION

Using I<Weather::Com::Location> objects is the way to access weather (and 
some location) information for one specific location (city).

You get I<Weather::Com::Location> objects by using a finder object
(see L<Weather::Com::Finder>).

I<Weather::Com::Location> is a subclass of I<Weather::Com::Cached>.
An instance of this class will update itself corresponding to the
caching rules any time one of its methods is called.

=head1 CONSTRUCTOR

=head2 new(hash or hashref)

The constructor will usually not be used directly because you get ready
to use location objects by using a finder.

If you ever want to instantiate location objects on your own, you have
to provide the same configuration hash or hashref to the constructor
you usually would provide to the C<new()> method of I<Weather::Com::Finder>.
In addition it is necessary to add a hash element C<location_id> to this
config hash. The C<location_id> has to be a valid I<weather.com> 
location id.

=head1 METHODS

=head2 id()

Returns the location id used to instantiate this location.

=head2 name()

Returns the name of the location as provided by I<weather.com>.

=head2 current_conditions()

Returns a I<Weather::Com::CurrentConditions> object containing the 
current conditions of the location.

The I<Weather::Com::CurrentConditions> object is instantiated with
the first call of the C<current_conditions()> method.

Please refer to L<Weather::Com::CurrentConditions> for further
details.

=head2 forecast() 

I<not implemented yet, comming soon>

Returns a I<Weather::Com::Forecast> object.

Please refer to L<Weather::Com::Forecast> for further
details.

=head2 latitude()

Returns the latitude of the location.

=head2 longitude()

Returns the longitude of the location.

=head2 localtime()

Returns the local time of the location.

This value is evaluated each time you call this method. We do not use
the value returned from I<weather.com> here because it does not make
any sence to use a cached value to show the current time.

The time is returned in the format C<hh:mm> where C<hh> is in 24 hour format.
To get a 12 hour format use C<localtime_ampm> instead.

  Sample: 14:34

=head2 localtime_ampm()

Returns the local time of the location.

This value is evaluated each time you call this method. We do not use
the value returned from I<weather.com> here because it does not make
any sence to use a cached value to show the current time.

The time is returned in the format C<hh:mm [AM|PM]>.
To get a 24 hour format use C<localtime> instead.

  Sample: 10:30 PM

=head2 sunrise()

Returns the time of sunrise in 24 hour format.

=head2 sunrise_ampm()

Returns the time of sunrise in 12 hour format (see C<localtime_ampm()>
for details).

=head2 sunset()

Returns the time of sunset in 24 hour format.

=head2 sunset_ampm()

Returns the time of sunset in 12 hour format (see C<localtime_ampm()>
for details).

=head2 timezone()

Returns the timezone offset to GMT (without respecting 
daylight savings time).

=head2 units()

Returns a I<Weather::Com::Units> object.

Please refer to L<Weather::Com::Units> for further
details.

=head1 SEE ALSO

See also documentation of L<Weather::Com>, L<Weather::Com::CurrentConditions>,
L<Weather::Com::Units>.

=head1 AUTHOR

Thomas Schnuecker, E<lt>thomas@schnuecker.deE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Thomas Schnuecker

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

The data provided by I<weather.com> and made accessible by this OO
interface can be used for free under special terms. 
Please have a look at the application programming guide of
I<weather.com> (http://www.weather.com/services/xmloap.html)

=cut
