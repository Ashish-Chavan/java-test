#!/usr/bin/perl
use strict;
use warnings;

# Simple Perl program example

# Variables
my $name = "Alex";
my $age  = 25;


# Array
my @colors = ("red", "blue", "green");
print "My favorite colors are:\n";
foreach my $color (@colors) {
    print "- $color\n";
}

my %user = (
    username => "alex123",
    email    => "alex@example.com",
    country  => "Ireland"
);

print "\nUser info:\n";
print "Username: $user{username}\n";
print "Email: $user{email}\n";
print "Country: $user{country}\n";

# Function
sub greet {
    my ($person) = @_;
    return "Nice to meet you, $person!";
}

print "\n" . greet($name) . "\n";

# File writing example
my $filename = "output.txt";

open(my $fh, ">", $filename) or die "Could not open file '$filename' $!";
print $fh "This file was created by a Perl script.\n";
close($fh);

print "\nFile '$filename' has been created successfully.\n";
