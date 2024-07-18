echo "$TARGET"

# if target equals "all" then run all tests

if [ "$TARGET" = "all" ]; then
    echo "Running all tests"
    coverage run -m pytest --log-cli-level=INFO -x -s -vvv --durations=5 --color=yes tests/ -W ignore::DeprecationWarning
else
    echo "Running tests for $TARGET"
    coverage run -m pytest --log-cli-level=INFO -x -s -vvv --durations=5 --color=yes "tests/test_$TARGET.py" -W ignore::DeprecationWarning
fi
cov_exit_code=$?

coverage report -m
coverage html > /dev/null
zip -r htmlcov.zip htmlcov > /dev/null
curl -XPOST -F 'data=@htmlcov.zip' repo:3000/upload?key=CI > /dev/null
coverage report -m > /dev/null

test_exit_code=$?
exit_code=$((cov_exit_code + test_exit_code))

echo "Coverage exit code: $cov_exit_code"
echo "Test exit code: $test_exit_code"
echo "Exit code: $exit_code"

exit "$exit_code"
