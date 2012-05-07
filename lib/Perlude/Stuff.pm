package Perlude::Stuff;
use Perlude;
use Modern::Perl;
use Exporter 'import';
use YAML;

our %EXPORT_TAGS =
( dbi       => [qw/ sql_hash sql_array sqlite  /]
, math      => [qw/ cartesianProduct indexes sum product whileBelow /]
, sequence  => [qw/ fibo look_and_say /]
, sysop     => [qw/ getpwent getpwent_hr /]
, XXX       => [qw/ XXX /]
);
our @EXPORT_OK = map @$_, values %EXPORT_TAGS;

sub XXX ($) { now { print YAML::Dump $_ } shift }

# system stuff ( See Perlude::Builtins ? )

sub f::getpwent    () { sub { my @e = getpwent or return; \@e } }
sub f::getpwent_hr () {
    sub {
        my %user;
        @user{qw/
            name passwd
            uid gid
            quota comment gcos dir shell
            expire
        /} = getpwent or return;
        \%user;
    }
}

# DBI stuff

=head1 DBI Stuff

=example 

    use Perlude;
    use DBI;
    use Perlude::Stuff ':dbi';
    ( my $db = DBI->connect('dbi:SQLite:dbname=passwd.db')
    )->{RaiseError} = 1;
    now { say $$_{login} } sql_hash $db, 'select login from passwd';

=cut

sub DBI::db::stream {
    require DBI;
    my $dbh  = shift;
    my $iter = shift;
    map {
        die unless /([ha])/i;
        $_ = $1 ~~ 'h' ? 'fetchrow_hashref' : 'fetchrow_arrayref'
    } $iter;
    (my $sth  = $dbh->prepare(@_))->execute;
    sub { $sth->$iter // () }
}

sub sql_hash  { (shift)->stream( h => @_ ) }
sub sql_array { (shift)->stream( a => @_ ) }
sub sqlite {
    require DBI;
    ( my $db = DBI->connect("dbi:SQLite:dbname=".shift) or die $!
    )->{RaiseError} = 1;
    $db;
}


=head1 Math Stuff

    my @matrices =
    ( [    1, 2, 3  ]
    , [qw< a  b  c >]
    , [qw< x  y  z >]
    );
    now {say join ',',@$_ } cartesianProduct @matrices;

=cut

sub indexes {
    my @v       = @_;      # v for values
    my @i       = (0)x@v;  # i for indexes
    my $done    = 0;       # $done for the win

    sub {
        return if $done;

        # we return the current indexes
        # and compute the next one
        my @r    = @i;

        # trying with column 0 first
        for (my $col  = 0;;) {

            # if incrementing the index of the col is still relevant
            # ($v[$col][$i[$col]] exists), we reach the next step 
            ++$i[$col] < @{$v[$col]} and return \@r;

            # else, we're back to 0 for this col
            $i[$col] = 0;

            # and we try the same job on the next col
            # (if there isn't, so the job is done)
            if (++$col > $#i) { $done = 1; return \@r }
        }
    }
}

sub cartesianProduct {
    my @v = @_;
    apply {

        # what we want is:
        # [ $v[0][ $i[0] ]
        # , $v[1][ $i[1] ]
        # ....

        my $i = $_;
        [ map { $$_[shift @$i] } @v ]

    } indexes @v
}

sub product ($) { now { state $r = 1; $r ?  $r*=$_ : 0 } shift }
sub sum     ($) { now { state $r = 0; $r+=$_ } shift }
sub whileBelow ($$) {
    my ($max,$l) = @_;
    takeWhile { $_ < $max } $l 
}

sub fibo {
    my @seed = @_;
    sub {
        push @seed, $seed[0] + $seed[1];
        shift @seed;
    }
}

sub look_and_say {
    my ($s,$r) = shift; 
    sub {
        $r = $s;
        $s =~ s/((.)\2*)/length($1).$2/eg;
        $r;
    }
}


1;
