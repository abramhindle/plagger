use strict;
use FindBin;
use t::TestPlagger;

our $output = "$FindBin::Bin/index.html";

test_plugin_deps;
plan tests => 2;
run_eval_expected;

END {
    unlink $output if -e $output;
}

__END__

=== generator testing
--- input config output_file
plugins:
  - module: Subscription::Config
    config:
      feed:
        - file://$t::TestPlagger::BaseDirURI/t/samples/non-http-link.xml
  - module: SmartFeed::All
  - module: Publish::Planet
    rule:
      expression: \$args->{feed}->id eq 'smartfeed:all'
    config:
      dir: $FindBin::Bin
      theme: sixapart-std
--- expected
my $content = $block->input;
like $content, qr!http://foo.example.com/!;
unlike $content, qr!bar.example.com!;


