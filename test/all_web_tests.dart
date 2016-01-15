import "link_matcher_test.dart" as link_matcher_test;
import "route_handle_test.dart" as route_handle_test;
import "route_view_test.dart" as route_view_test;
import "url_matcher_test.dart" as url_matcher_test;
import "url_template_test.dart" as url_template_test;
import "providers/browser_history_test.dart" as browser_history_test;
import "providers/hash_history_test.dart" as hash_history_test;
import "providers/memory_history_test.dart" as memory_history_test;

main() {
  link_matcher_test.main();
  route_handle_test.main();
  route_view_test.main();
  url_matcher_test.main();
  url_template_test.main();

  browser_history_test.main();
  hash_history_test.main();
  memory_history_test.main();
}
