#!/usr/bin/perl -w

use 5.10.0;
use warnings;
use strict;

use Time::HiRes qw( tv_interval gettimeofday );
use AnyEvent;
use AnyEvent::HTTP::LWP::UserAgent;
use Data::Validate::URI qw(is_uri);
use Carp;

$| = 1;
my %stat;

say <<EOF;
Please enter the URL's separated by spaces
For exit enter q
EOF

my $idle;
my $ua = AnyEvent::HTTP::LWP::UserAgent->new;
while (1) {
    my $cv = AnyEvent->condvar;
    my $r; $r = AnyEvent->io(
        fh   => \*STDIN,
        poll => 'r',
        cb   => sub {
            chomp(my $input = <STDIN>);
            undef $r;
            $cv->send($input);
        },
    );
    if ( my $data = $cv->recv ) {
        last if $data =~ /^q$/i;
        $idle = AnyEvent->idle (
            cb => sub { 
                unless ($AnyEvent::HTTP::ACTIVE) {
                    undef $idle; 
                    statistica();
                }
            },
        );
        fetch($data);
    }
}

sub fetch {
    my $data = shift;

    my @urls = grep { is_uri $_ } split /\s+/, $data;
    
    my $cv = AnyEvent->condvar;
    $cv->begin;
    my $start;
    foreach my $url (@urls) {
        
        $start = [gettimeofday];
        $cv->begin;
        $ua->get_async($url)->cb(sub {
                                     my $res = shift->recv;
                                     if ($res->is_success) {
                                         $stat{$url} = tv_interval($start, [gettimeofday]);
                                         say $res->content;
                                     }
                                     else {
                                         carp('Error: ' . $res->status_line);
                                     }                                             
                                     $cv->end;
                                 });
    }
    $cv->end;
    $cv->recv;
}

sub start_timer {
    $stat{$_[0]} = [gettimeofday];
}

sub stop_timer {
    $stat{$_[0]} = tv_interval ($stat{$_[0]}, [gettimeofday]);
};

sub statistica {
    while (my ($url, $interval) = each %stat) {
        say sprintf "%s (%.2f ms)", $url, $interval;
    }
}

__END__
