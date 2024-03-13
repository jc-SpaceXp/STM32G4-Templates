#include "greatest.h"

TEST test_PASS(void)
{
	ASSERT_EQ(1, 1);
	PASS();
}

SUITE(all_tests_suite)
{
	RUN_TEST(test_PASS);
}

GREATEST_MAIN_DEFS();

int main(int argc, char **argv)
{
	(void) argc;
	(void) argv;

	GREATEST_MAIN_BEGIN();

	RUN_SUITE(all_tests_suite);

	GREATEST_MAIN_END(); // exapnds to a return statement
}
