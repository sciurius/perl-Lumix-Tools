# Lumix-Tools

Lumix::Tools provides some tools to interact with a Panasonic Lumix
digital camera connected via Wifi. It may work with other cameras.
I have developed it for (and tested with) my TZ200.

Example:

    use Lumix::Tools;
	my $cam = Lumix::Tools->new( device => '192.168.1.82' );
	print "Current mode = ", $cam->state->{cammode}, ".\n";
	my $imgs = $cam->browsedirectchildren;
	print scalar(@$imgs), " images on camera."
	
See also the script directory for example programs.

## INSTALLATION

To install this module, run the following commands:

	perl Makefile.PL
	make
	make test
	make install

## SCRIPTS

`scripts/fetch.pl`

Ths program attempts to transfer all new images to a predefined
location in a predefined format. See the program docs for more info.

`scripts/watch.sh`

A script to wait for the camera to connect, and transfers all new
images.

Requires the `fetch.pl` script.

`scripts/4kstills.sh`

A script to extract the images from a 4K burst.

Requires `vlc` and `exiftool`.

## SUPPORT AND DOCUMENTATION

Development of this module takes place on GitHub:
https://github.com/sciurius/perl-Lumix-Tools.

You can find documentation for this module with the perldoc command.

    perldoc Lumix::Tools

Please report any bugs or feature requests using the issue tracker on
GitHub.

## COPYRIGHT AND LICENCE

Copyright (C) 2021 Johan Vromans

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

