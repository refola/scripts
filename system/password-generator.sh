#!/bin/bash
# password-generator.sh

usage="password-generator [options ...] {pattern-name}
password-generator [options ...] custom {custom-pattern}
password-generator --base64 [options ..]

Generate password-like strings from '/dev/random'. Options are as
follows.

--base64
             After reading the bytes, encode them in with 'base64' and
             output that instead of filtering by a pattern.

--bytes      number
             How many bytes to read from the randomness source. Note
             that (except in base64 mode) this number needs to be
             substantially bigger than your desired password length,
             especially with more limited pattern types. For example,
             the 'pin' pattern is only 3.9% efficient, so on average
             you would need about 26 times as many bytes generated as
             symbols used in your password. Even the most advanced
             options need about 3 times as many bytes.

--source     file
             Read bytes from the given file instead of from
             '/dev/random'.
             Warning: This option makes it easy to compromise your own
             security. As such, it is only recommended for testing
             purposes.


'pattern-name' must be one of the following:

  all-us     a-zA-Z0-9 \`~!@#$%^&*()[]{}',.\"<>/=\\\\?+|\\-_;:
             All the directly-typable characters on my United States keyboard.

  alnum      a-z0-9
             For limited systems that at least go beyond digits.

  basic      a-zA-Z0-9!@#$%^&*()
             Both cases of letters, numbers, and 'shifted number' symbols.

  custom
             This should enable arbitrary patterns of your choice. But
             there could be all sorts of limitations that I'm unaware
             of (number of bytes in the character? limitations of the
             underlying 'tr' implementation?). At minimum, subsets of
             existing patterns should be fine.

  default
             Currently this is an alias for 'all-us'.

  pin        0-9
             For low-security systems that won't let you use good passwords.


Note: This script was originally inspired by
http://blog.colovirt.com/2009/01/07/linux-generating-strong-passwords-using-randomurandom/
"

## usage
# Print usage information and exit.
usage() {
    echo "$usage"
    exit 1
}

## pw-gen pattern delay random-source [b64]
# Generate bytes from random-source for delay time and output results
# filtered to pattern.
pw-gen() {
    local pattern="$1"
    local bytes="$2"
    local randsrc="$3"
    local b64="$4"
    local file
    file="$(mktemp)" || exit 1

    echo "Getting the first $bytes from $randsrc."
    head --bytes="$bytes" "$randsrc" > "$file"

    if [ "$b64" = "b64" ]; then
        echo -e "Base64-encoding bytes.\n"
        base64 --wrap=20 "$file"
    else
        echo -e "Filtering bytes by $pattern\n"
        # Filtering wastes a lot of random bytes, but I don't know of
        # a _simple_ and _general_ way to improve byte economy
        # (currently between 3.9% and 37.1% with built-in patterns)
        # without risking biasing the output.
        tr --delete --complement "$pattern" < "$file" | fold --width=20
        echo
    fi
    rm "$file"
}

main() {
    # Get options
    local b64 bytes randsrc
    while true; do
        case "$1" in
            --base64)
                b64=b64
                shift 1
                # Pass the pattern argument check even if the user
                # didn't provide a pattern.
                set -- "$@" default
                ;;
            --bytes)
                bytes="$2"
                shift 2
                ;;
            --source)
                randsrc="$2"
                shift 2
                ;;
            *) # End of options. Assume remaining args define pattern.
                break
                ;;
        esac
    done

    # Get pattern
    local pattern
    case "$1" in
        pin)
            pattern="0-9"
            ;;
        alnum)
            pattern="a-z0-9"
            ;;
        basic)
            pattern="a-zA-Z0-9!@#$%^&*()"
            ;;
        all-us|default)
            # "\\\\" -> "\\" by bash and "\\" -> "\" by tr
            pattern="a-zA-Z0-9 \`~!@#$%^&*()[]{}',.\"<>/=\\\\?+|\-_;:"
            ;;
        custom)
            pattern="$2"
            ;;
        *)
            usage
            ;;
    esac

    # Set defaults if unset.
    bytes="${bytes-200}"
    randsrc="${randsrc-/dev/random}"

    # Generate the passwords.
    pw-gen "$pattern" "$bytes" "$randsrc" $b64
}

main "$@"
