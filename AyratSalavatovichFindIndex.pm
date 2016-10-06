package AyratSalavatovichFindIndex;

use strict;
use warnings;

use vars qw($VERSION);

$VERSION = '0.01';

sub new {
    my ( $class ) = @_;
    bless {}, $class;
}

sub _avg(@) {
    @_ or return 0;
    
    my $sum = 0;
    $sum += $_ foreach @_;
    int( $sum / scalar @_ );
};

sub find {
    my ( $self, $target, $list ) = @_;

    @$list or return undef;

    my ($low, $high) = (0, $#$list);
    my $step = 1;
    
    return ($low, $step) if @$list == 1 or $target <= $list->[0];
    return ($high, $step) if $target >= $list->[$#$list];

    my $middle = _avg($low, $high);

    for ( ;$low <= $high; $middle = _avg($low, $high) ) {
        $step++;
        if ( $list->[$middle] > $target ) {
            $high = $middle - 1;
        }
        elsif ( $list->[$middle] < $target ) {
            $low = $middle + 1;
        } else {
            last;
        }
    }

    if ( $high < $low ) {
        if ( $target - $list->[$high] <=  $list->[$low] - $target) {
            return ($high, $step);
        } else {
            return ($low, $step);
        }
    } else {
        return ($middle, $step);
    }
}

1;
