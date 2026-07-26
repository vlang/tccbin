#include <math.h>
#include <stdint.h>
#include <stdio.h>

unsigned int _clearfp(void);
unsigned int _controlfp(unsigned int new_value, unsigned int mask);
unsigned int _statusfp(void);

#define _SW_INEXACT 0x00000001U
#define _SW_UNDERFLOW 0x00000002U
#define _SW_INVALID 0x00000010U
#define _RC_UP 0x00000200U
#define _MCW_RC 0x00000300U

typedef union {
	double value;
	uint64_t bits;
} double_bits;

typedef enum {
	TEST_FP_ZERO,
	TEST_FP_SUBNORMAL,
	TEST_FP_NORMAL,
	TEST_FP_INFINITY,
	TEST_FP_QNAN,
	TEST_FP_SNAN
} test_fp_class;

typedef struct {
	double input;
	double expected;
} exp2_case;

static const double vf_[] = {
	4.9790119248836735e+00,
	7.7388724745781045e+00,
	-2.7688005719200159e-01,
	-5.0106036182710749e+00,
	9.6362937071984173e+00,
	2.9263772392439646e+00,
	5.2290834314593066e+00,
	2.7279399104360102e+00,
	1.8253080916808550e+00,
	-8.6859247685756013e+00,
};

static const double exp2_[] = {
	3.1537839463286288034313104e+01,
	2.1361549283756232296144849e+02,
	8.2537402562185562902577219e-01,
	3.1021158628740294833424229e-02,
	7.9581744110252191462569661e+02,
	7.6019905892596359262696423e+00,
	3.7506882048388096973183084e+01,
	6.6250893439173561733216375e+00,
	3.5438267900243941544605339e+00,
	2.4281533133513300984289196e-03,
};

static uint64_t bits_of(double value)
{
	double_bits converted;
	converted.value = value;
	return converted.bits;
}

static double value_from_bits(uint64_t bits)
{
	double_bits converted;
	converted.bits = bits;
	return converted.value;
}

static test_fp_class class_of_bits(uint64_t bits)
{
	uint64_t magnitude = bits & 0x7fffffffffffffffULL;
	uint64_t fraction = magnitude & 0x000fffffffffffffULL;

	if (magnitude == 0)
		return TEST_FP_ZERO;
	if ((magnitude & 0x7ff0000000000000ULL) == 0)
		return TEST_FP_SUBNORMAL;
	if ((magnitude & 0x7ff0000000000000ULL) !=
		0x7ff0000000000000ULL)
		return TEST_FP_NORMAL;
	if (fraction == 0)
		return TEST_FP_INFINITY;
	if (fraction & 0x0008000000000000ULL)
		return TEST_FP_QNAN;
	return TEST_FP_SNAN;
}

static int strict_same_class(double actual, double expected)
{
	uint64_t actual_bits = bits_of(actual);
	uint64_t expected_bits = bits_of(expected);

	return class_of_bits(actual_bits) == class_of_bits(expected_bits) &&
		(actual_bits >> 63) == (expected_bits >> 63);
}

static int strict_close(double actual, double expected, double tolerance)
{
	double difference;
	test_fp_class expected_class;

	if (!strict_same_class(actual, expected))
		return 0;
	expected_class = class_of_bits(bits_of(expected));
	if (expected_class == TEST_FP_ZERO ||
		expected_class == TEST_FP_INFINITY ||
		expected_class == TEST_FP_QNAN ||
		expected_class == TEST_FP_SNAN)
		return 1;
	difference = actual - expected;
	if (difference < 0.0)
		difference = -difference;
	if (expected != 0.0) {
		tolerance *= expected;
		if (tolerance < 0.0)
			tolerance = -tolerance;
	}
	return difference <= tolerance;
}

static double exact_power_of_two(int exponent)
{
	if (exponent < -1022)
		return value_from_bits(1ULL << (exponent + 1074));
	return value_from_bits((uint64_t) (exponent + 1023) << 52);
}

int main(void)
{
	exp2_case special_cases[] = {
		{-2000.0, 0.0},
		{2000.0, value_from_bits(0x7ff0000000000000ULL)},
		{value_from_bits(0x7ff0000000000000ULL),
			value_from_bits(0x7ff0000000000000ULL)},
		{value_from_bits(0x7ff8000000000000ULL),
			value_from_bits(0x7ff8000000000000ULL)},
		{1024.0, value_from_bits(0x7ff0000000000000ULL)},
		{-1.07399999999999e+03, 5e-324},
		{3.725290298461915e-09, 1.0000000025821745},
	};
	volatile double_bits signaling_nan;
	volatile double underflow_input = -2000.0;
	volatile long double exp2l_input = 1024.0L;
	volatile double_bits below_1024;
	unsigned int special_failures = 0;
	unsigned int range_failures = 0;
	unsigned int diagnostic_failures = 0;
	unsigned int saved_control;
	unsigned int restored_control;
	unsigned int status;
	unsigned int i;
	int first_failed_exponent = 0;
	double first_actual = 0.0;
	double first_expected = 0.0;
	int exponent;

	for (i = 0; i < sizeof(special_cases) / sizeof(special_cases[0]); i++) {
		double actual = exp2(special_cases[i].input);

		if (!strict_close(actual, special_cases[i].expected, 4e-16)) {
			special_failures++;
			fprintf(stderr,
				"exp2 special case %u failed: input=%016llx expected=%016llx actual=%016llx\n",
				i,
				(unsigned long long) bits_of(special_cases[i].input),
				(unsigned long long) bits_of(special_cases[i].expected),
				(unsigned long long) bits_of(actual));
		}
	}

	for (exponent = -1074; exponent < 1024; exponent++) {
		double expected = exact_power_of_two(exponent);
		double actual = exp2((double) exponent);

		if (bits_of(actual) != bits_of(expected)) {
			if (range_failures == 0) {
				first_failed_exponent = exponent;
				first_actual = actual;
				first_expected = expected;
			}
			range_failures++;
		}
	}
	if (range_failures != 0) {
		fprintf(stderr,
			"exp2 integer range failed %u times; first n=%d expected=%016llx actual=%016llx\n",
			range_failures,
			first_failed_exponent,
			(unsigned long long) bits_of(first_expected),
			(unsigned long long) bits_of(first_actual));
	}

	signaling_nan.bits = 0x7ff0000000000001ULL;
	_clearfp();
	{
		double actual = exp2(signaling_nan.value);

		status = _statusfp();
		if (class_of_bits(bits_of(actual)) != TEST_FP_QNAN) {
			diagnostic_failures++;
			fprintf(stderr,
				"exp2 sNaN quieting failed: input=7ff0000000000001 actual=%016llx class=%u\n",
				(unsigned long long) bits_of(actual),
				(unsigned int) class_of_bits(bits_of(actual)));
		}
		if ((status & _SW_INVALID) == 0) {
			diagnostic_failures++;
			fprintf(stderr,
				"exp2 sNaN invalid status failed: status=%08x expected-mask=%08x\n",
				status, _SW_INVALID);
		}
	}
	_clearfp();

	saved_control = _controlfp(0, 0);
	_controlfp(_RC_UP, _MCW_RC);
	_clearfp();
	{
		double actual = exp2(underflow_input);

		status = _statusfp();
		if (bits_of(actual) != 1ULL) {
			diagnostic_failures++;
			fprintf(stderr,
				"exp2 upward underflow value failed: input=-2000 expected=0000000000000001 actual=%016llx\n",
				(unsigned long long) bits_of(actual));
		}
		if ((status & _SW_UNDERFLOW) == 0) {
			diagnostic_failures++;
			fprintf(stderr,
				"exp2 upward underflow status failed: status=%08x expected-mask=%08x\n",
				status, _SW_UNDERFLOW);
		}
		if ((status & _SW_INEXACT) == 0) {
			diagnostic_failures++;
			fprintf(stderr,
				"exp2 upward inexact status failed: status=%08x expected-mask=%08x\n",
				status, _SW_INEXACT);
		}
	}
	restored_control = _controlfp(saved_control, _MCW_RC);
	if ((restored_control & _MCW_RC) != (saved_control & _MCW_RC)) {
		diagnostic_failures++;
		fprintf(stderr,
			"floating-point rounding restoration failed: saved=%08x restored=%08x\n",
			saved_control, restored_control);
	}
	_clearfp();

	{
		double actual = (double) exp2l(exp2l_input);

		if (bits_of(actual) != 0x7ff0000000000000ULL) {
			diagnostic_failures++;
			fprintf(stderr,
				"exp2l overflow boundary failed: input=1024 expected=7ff0000000000000 actual=%016llx\n",
				(unsigned long long) bits_of(actual));
		}
	}

	for (i = 0; i < sizeof(vf_) / sizeof(vf_[0]); i++) {
		double actual = exp2(vf_[i]);

		if (!strict_close(actual, exp2_[i], 1e-9)) {
			diagnostic_failures++;
			fprintf(stderr,
				"exp2 V fractional case %u failed: input=%.17g expected=%.17g actual=%.17g expected-class=%u actual-class=%u\n",
				i, vf_[i], exp2_[i], actual,
				(unsigned int) class_of_bits(bits_of(exp2_[i])),
				(unsigned int) class_of_bits(bits_of(actual)));
		}
	}

	below_1024.bits = 0x408fffffffffffffULL;
	{
		double actual = exp2(below_1024.value);
		uint64_t actual_bits = bits_of(actual);

		if (class_of_bits(actual_bits) != TEST_FP_NORMAL ||
			(actual_bits >> 63) != 0) {
			diagnostic_failures++;
			fprintf(stderr,
				"exp2 predecessor of 1024 failed: input=408fffffffffffff actual=%016llx class=%u\n",
				(unsigned long long) actual_bits,
				(unsigned int) class_of_bits(actual_bits));
		}
	}

	return special_failures != 0 || range_failures != 0 ||
		diagnostic_failures != 0;
}
