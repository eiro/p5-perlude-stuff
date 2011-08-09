package Perlude::Stuff;
use Perlude;
use Modern::Perl;
use Exporter 'import';

our %EXPORT_TAGS =
( dbi   => [qw/ sql_hash sql_array  /]
, shell => [qw/ cat zcat /]
, math  => [qw/ cartesianProduct indexes /]
);

our @EXPORT_OK = map @$_, values %EXPORT_TAGS;

# system stuff ( See Perlude::Builtins ? )

sub f::getpwent    () { enlist { my @e = getpwent or return; \@e } }
sub f::getpwent_hr () {
    enlist {
        my %user;
        @user{qw/ login x uid gid gecos home shell /} = getpwent
            or return;
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
    traverse { say $$_{login} } sql_hash $db, 'select login from passwd';

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
    enlist { $sth->$iter // () }
}

sub sql_hash  { (shift)->stream( h => @_ ) }
sub sql_array { (shift)->stream( a => @_ ) }

=head1 Shell Stuff

=examples

   traverse {print if /foo/} zcat <log/*.gz>; 
   traverse {print if /foo/} cat <log/*.log>; 

=head2 todo: reinvent find

    # a walker + a selector ? 
    # a DSL like {^}.*riak.*/{Df}.*/

=cut

sub cat {
    my $param = ref $_[0] ? shift : {};
    my $io = '<'.( delete $$param{io} || '' );
    %$param and die "unparsed params: ", join keys %$param;
    my @files = @_;
    my ($fh,$v);
    enlist {
        $fh or open $fh,$io,shift @files || return;
        return $v if defined ( $v = <$fh> );
        $fh = undef;
    }
}

sub zcat {
    require PerlIO::gzip;
    cat {qw/io :gzip/}, @_
}

=head1 Math Stuff

    my @matrices =
    ( [    1, 2, 3  ]
    , [qw< a  b  c >]
    , [qw< x  y  z >]
    );
    traverse {say join ',',@$_ } cartesianProduct @matrices;

=cut

sub indexes {
    my @v       = @_;      # v for values
    my @i       = (0)x@v;  # i for indexes
    my $done    = 0;       # $done for the win

    enlist {
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

1;
