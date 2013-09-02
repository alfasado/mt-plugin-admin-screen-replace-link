package AdminScreenReplaceLink::Plugin;
use strict;

sub _preview_strip {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $preview_url = $param->{ preview_url };
    my ( $search, $replace ) = __get_config( $app, $app->param( 'blog_id' ) );
    if ( $search && $replace ) {
        $search = quotemeta( $search );
        $preview_url =~ s/$search/$replace/;
        $param->{ preview_url } = $preview_url;
    }
}

sub _asset_list {
    my ( $cb, $app, $param, $tmpl ) = @_;
    my $object_loop = $param->{ object_loop };
    my @new_loop;
    for my $obj ( @$object_loop ) {
        for my $key ( keys( %$obj ) ) {
            my $blog_id = $obj->{ blog_id };
            if ( ( $key eq 'metadata_json' ) || ( $key =~ /url$/ ) ) {
                my ( $search, $replace ) = __get_config( $app, $blog_id );
                $search = quotemeta( $search );
                my $col = $obj->{ $key };
                $col =~ s/$search/$replace/g;
                $obj->{ $key } = $col;
            }
        }
        push ( @new_loop, $obj );
    }
    $param->{ object_loop } = \@new_loop;
}

sub _list_entry {
    my ( $cb, $app, $res, $objs ) = @_;
    my $entries = $res->{ objects };
    my $replace;
    for my $entry ( @$entries ) {
        my $new;
        for my $col( @$entry ) {
            if ( $col =~ /^<span/ ) {
                if ( $col =~ /&blog_id=([0-9]{1,})&/ ) {
                    my ( $search, $replace ) = __get_config( $app, $1 );
                    if ( $search && $replace ) {
                        $search  = MT::Util::encode_html( $search );
                        $replace = MT::Util::encode_html( $replace );
                        $search = quotemeta( $search );
                        $col =~ s/$search/$replace/;
                    }
                }
            }
            push( @$new, $col );
        }
        push ( @$replace, $new );
    }
    $res->{ objects } = $replace;
}

sub _list_asset {
    my ( $cb, $app, $res, $objs ) = @_;
    my $assets = $res->{ objects };
    my $replace;
    for my $asset ( @$assets ) {
        my $new;
        for my $col( @$asset ) {
            if ( $col =~ /__mode=view&_type=asset&blog_id=([0-9]{1,})/ ) {
                my ( $search, $replace ) = __get_config( $app, $1 );
                if ( $search && $replace ) {
                    $search  = MT::Util::encode_html( $search );
                    $replace = MT::Util::encode_html( $replace );
                    $search = quotemeta( $search );
                    $col =~ s/$search/$replace/g;
                }
            }
            push( @$new, $col );
        }
        push ( @$replace, $new );
    }
    $res->{ objects } = $replace;
}

sub _list_campaign {
    my ( $cb, $app, $res, $objs ) = @_;
    my $campaigns = $res->{ objects };
    my $replace;
    for my $campaign ( @$campaigns ) {
        my $new;
        my $blog_id;
        for my $col( @$campaign ) {
            if ( $col =~ /<img/ ) {
                if ( $col =~ /&blog_id=([0-9]{1,})/ ) {
                    $blog_id = $1;
                }
            }
        }
        for my $col( @$campaign ) {
            if ( $col =~ /<a/ ) {
                my ( $search, $replace ) = __get_config( $app, $blog_id );
                if ( $search && $replace ) {
                    $search  = MT::Util::encode_html( $search );
                    $replace = MT::Util::encode_html( $replace );
                    $search = quotemeta( $search );
                    $col =~ s/$search/$replace/g;
                }
            }
            push( @$new, $col );
        }
        push ( @$replace, $new );
    }
    $res->{ objects } = $replace;
}

sub _footer {
    my ( $cb, $app, $tmpl ) = @_;
    my ( $search, $replace ) = __get_config( $app );
    if ( (! $search ) || (! $replace ) ) {
        return;
    }
    $search  = MT::Util::encode_js( $search );
    $replace = MT::Util::encode_js( $replace );
    my $js = <<MTML;
<script type="text/javascript">
jQuery(function(){
jQuery('a').each(function(){
var link = this.href;
if (! link.match( '<mt:var name="script_url" escape="js">' ) ) {
    this.href = link.replace( '${search}', '${replace}' );
}})
jQuery('img').each(function(){
var src = this.src;
this.src = src.replace( '${search}', '${replace}' );
})
});
</script>
MTML
    my $pointer = '</body>';
    $$tmpl =~ s!$pointer!$js</body>!;
}

sub __get_config {
    my ( $app, $blog_id ) = @_;
    my $plugin = MT->component( 'AdminScreenReplaceLink' );
    my ( $search, $replace );
    my $blog;
    if ( $blog_id ) {
        $blog = MT::Blog->load( $blog_id );
    } else {
        if ( $blog = $app->blog ) {
            $blog_id = $blog->id;
        }
    }
    if ( $blog ) {
        $search  = $plugin->get_config_value( 'adminscreenreplacelink_search', 'blog:' . $blog->id );
        $replace = $plugin->get_config_value( 'adminscreenreplacelink_replace', 'blog:' . $blog->id );
        if ( (! $search ) && (! $replace ) ) {
            if ( $blog->class eq 'blog' ) {
                $search  = $plugin->get_config_value( 'adminscreenreplacelink_search', 'blog:' . $blog->parent_id );
                $replace = $plugin->get_config_value( 'adminscreenreplacelink_replace', 'blog:' . $blog->parent_id );
            }
        }
    }
    if ( (! $search ) && (! $replace ) ) {
        $search  = $plugin->get_config_value( 'adminscreenreplacelink_search' );
        $replace = $plugin->get_config_value( 'adminscreenreplacelink_replace' );
    }
    return ( $search, $replace );
}

1;