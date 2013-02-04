package AdminScreenReplaceLink::Plugin;
use strict;

sub _footer {
    my ( $cb, $app, $tmpl ) = @_;
    my $plugin = MT->component( 'AdminScreenReplaceLink' );
    my ( $search, $replace );
    if ( my $blog = $app->blog ) {
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
    if ( (! $search ) || (! $replace ) ) {
        return;
    }
    my $js = <<MTML;
<script type="text/javascript">
jQuery(function(){
jQuery('a').each(function(){
var link = this.href;
if (! link.match( '<mt:var name="script_url" escape="js">' ) ) {
    this.href = link.replace( '${search}', '${replace}' );
}})
});
</script>
MTML
    my $pointer = '</body>';
    $$tmpl =~ s!$pointer!$js</body>!;
}

1;