from libc.stdlib cimport *

cdef extern from "ctype.h":
    int toupper(int)

cdef extern from "stdlib.h":
    void *memset(void *str, int c, size_t n)

cdef char upper_char(char c):
    return <char>toupper(<int>c)

def soundex(s):
    cdef short uni = False
    if isinstance(s, unicode):
        s = s.encode('ASCII')
        uni = True

    cdef:
        char* word = s
        Py_ssize_t word_len = len(s)
        char result[5]

    if word_len == 0:
        return "0000"

    result[0] = upper_char(word[0])
    result[1] = '0'
    result[2] = '0'
    result[3] = '0'
    result[4] = 0

    cdef:
        char code
        char last_code = '0'
        Py_ssize_t length = 1
        Py_ssize_t loops = 0
        char c

    for c in word[:word_len]:
        c = upper_char(c)
        loops += 1

        if c in [66, 70, 80, 86]:
            code = '1'
        elif c in [67, 71, 74, 75, 81, 83, 88, 90]:
            code = '2'
        elif c in [68, 84]:
            code = '3'
        elif c == 76:
            code = '4'
        elif c in [77, 78]:
            code = '5'
        elif c == 82:
            code = '6'
        elif c in [72, 87]:
            continue
        else:
            last_code = '0'
            continue

        if code == last_code:
            continue

        last_code = code

        if loops > 1:
            result[length] = code
            length += 1

        if length == 4:
            break

    if uni:
        # Return unicode if that was what we were passed in
        return result[:4].decode('ASCII')

    return result


def match_rating_codex(s):
    cdef short uni = False
    if isinstance(s, unicode):
        s = s.encode('ASCII')
        uni = True

    cdef:
        char* word = s
        Py_ssize_t word_len = len(s)
        Py_ssize_t i
        Py_ssize_t j = 0
        char c
        char prev = 0

        char codex[7]

    for i in range(0, word_len):
        if j >= 7:
            break

        c = upper_char(word[i])

        if c == ' ':
            continue
        elif c in [65, 69, 73, 79, 85]:
            if i != 0:
                continue

        if c == prev:
            continue

        if j == 6:
            codex[3] = codex[4]
            codex[4] = codex[5]
            j = 5

        codex[j] = c
        j += 1

    codex[j] = 0

    if uni:
        return codex.decode('ASCII')
    return codex


def match_rating_comparison(s1, s2):
    s1_codex_py = match_rating_codex(s1)
    if not s1_codex_py:
        return -1

    s2_codex_py = match_rating_codex(s2)
    if not s2_codex_py:
        return -1

    cdef:
        char* s1_codex = s1_codex_py
        char* s2_codex = s2_codex_py
        char* longer

        char c

        Py_ssize_t s1c_len = len(s1_codex)
        Py_ssize_t s2c_len = len(s2_codex)

        Py_ssize_t i, j, diff

    if abs(s1c_len - s2c_len) >= 3:
        return -1

    for i in range(0, _min(s1c_len, s2c_len)):
        if s1_codex[i] == s2_codex[i]:
            s1_codex[i] = ' '
            s2_codex[i] = ' '

    i = s1c_len - 1
    j = s2c_len - 1
    while i != 0 and j != 0:
        if s1_codex[i] == ' ':
            i -= 1
            continue

        if s2_codex[j] == ' ':
            j -= 1
            continue

        if s1_codex[i] == s2_codex[j]:
            s1_codex[i] = ' '
            s2_codex[j] = ' '

        i -= 1
        j -= 1

    if s1c_len > s2c_len:
        longer = s1_codex
    else:
        longer = s2_codex

    diff = 0
    for c in longer:
        if c != ' ':
            diff += 1

    diff = 6 - diff

    i = s1c_len + s2c_len
    if i <= 4:
        return diff >= 5
    elif i <= 7:
        return diff >= 4
    elif i <= 11:
        return diff >= 3

    return diff >= 2


cdef unicode tounicode(char *s):
    return s.decode('UTF-8', 'strict')

cdef inline unsigned _min(unsigned a, unsigned b):
    return a if a <= b else b

def levenshtein_distance(s1, s2):
    if not isinstance(s1, unicode):
        s1 = tounicode(s1)
    if not isinstance(s2, unicode):
        s2 = tounicode(s2)

    return _levenshtein_distance(s1, s2)

cdef Py_ssize_t _levenshtein_distance(unicode s1, unicode s2):
    cdef:
        Py_ssize_t s1_len = len(s1)
        Py_ssize_t s2_len = len(s2)
        Py_ssize_t rows = s1_len + 1
        Py_ssize_t cols = s2_len + 1
        Py_ssize_t i, j

        unsigned result, d1, d2, d3

        unsigned *dist = <unsigned*>malloc(rows * cols * sizeof(unsigned))

    for i in range(0, rows):
        dist[i * cols] = i

    for j in range(0, cols):
        dist[j] = j

    for j in range(1, cols):
        for i in range(1, rows):
            if s1[i - 1] == s2[j - 1]:
                dist[(i * cols) + j] = dist[((i - 1) * cols) + (j - 1)]
            else:
                d1 = dist[((i - 1) * cols) + j] + 1;
                d2 = dist[(i * cols) + (j - 1)] + 1;
                d3 = dist[((i - 1) * cols) + (j - 1)] + 1;

                dist[(i * cols) + j] = _min(d1, _min(d2, d3));

    result = dist[(cols * rows) - 1]

    free(dist)

    return result

def damerau_levenshtein_distance(s1, s2):
    if not isinstance(s1, unicode):
        s1 = tounicode(s1)
    if not isinstance(s2, unicode):
        s2 = tounicode(s2)

    return _damerau_levenshtein_distance(s1, s2)

cdef Py_ssize_t _damerau_levenshtein_distance(unicode s1, unicode s2):
    cdef:
        Py_ssize_t s1_len = len(s1)
        Py_ssize_t s2_len = len(s2)
        Py_ssize_t rows = s1_len + 1
        Py_ssize_t cols = s2_len + 1

        Py_ssize_t i, j
        Py_ssize_t d1, d2, d3, d_now
        unsigned short cost

        Py_ssize_t *dist = <Py_ssize_t*>malloc(rows * cols * sizeof(Py_ssize_t))

        Py_UNICODE s1_prev, s2_prev

    for i in range(0, rows):
        dist[i * cols] = i

    for j in range(0, cols):
        dist[j] = j

    for i in range(1, rows):
        for j in range(1, cols):
            s1_prev = s1[i-1]
            s2_prev = s2[j - 1]

            if s1_prev == s2_prev:
                cost = 0
            else:
                cost = 1

            d1 = dist[((i - 1) * cols) + j] + 1;
            d2 = dist[(i * cols) + (j - 1)] + 1;
            d3 = dist[((i - 1) * cols) + (j - 1)] + cost;

            d_now = _min(d1, _min(d2, d3));

            if (i > 2 and j > 2 and s1_prev == s2[j - 2] and
                s1[i - 2] == s2_prev):

                d1 = dist[((i - 2) * cols) + (j - 2)] + cost;
                d_now = _min(d_now, d1);

            dist[(i * cols) + j] = d_now;

    d_now = dist[(cols * rows) - 1]
    free(dist)

    return d_now

cdef inline int _notnum(char c):
    if c > 57 or c < 48:
        return True
    return False

cdef double _jaro_winkler(unicode ying, unicode yang, int long_tolerance,
                          int winklerize):
    cdef:
        char* ying_flag = <char*>0
        char* yang_flag = <char*>0

        double weight

        Py_ssize_t ying_length, yang_length, min_length
        Py_ssize_t search_range
        Py_ssize_t lowlim, hilim
        Py_ssize_t trans_count, common_chars

        Py_ssize_t i, j, k

    ying_length = len(ying)
    yang_length = len(yang)

    if ying_length == 0 or yang_length == 0:
        return 0.0

    if ying_length > yang_length:
        search_range = ying_length
        min_length = yang_length
    else:
        search_range = yang_length
        min_length = ying_length

    ying_flag = <char*>calloc(ying_length + 1, sizeof(char))
    yang_flag = <char*>calloc(yang_length + 1, sizeof(char))

    # Why were these there in addition to calloc?
    # Nothing is ever compared against ' '.
    # memset(ying_flag, ' ', ying_length)
    # memset(yang_flag, ' ', yang_length)

    search_range = (search_range / 2) - 1
    if search_range < 0:
        search_range = 0

    # Looking only within the search range, count and flag the matched pairs
    common_chars = 0
    for i in range(0, ying_length):
        if i >= search_range:
            lowlim = i - search_range
        else:
            lowlim = 0

        if (i + search_range) <= (yang_length - 1):
            hilim = i + search_range
        else:
            hilim = yang_length - 1

        for j in range(lowlim, hilim + 1):
            if yang_flag[j] != '1' and yang[j] == ying[i]:
                yang_flag[j] = '1'
                ying_flag[i] = '1'
                common_chars += 1
                break

    # If no characters in common - return
    if common_chars == 0:
        free(ying_flag)
        free(yang_flag)
        return 0.0

    # Count the number of transpositions
    k = 0
    trans_count = 0
    for i in range(0, ying_length):
        if ying_flag[i] == '1':
            for j in range(k, yang_length):
                if yang_flag[j] == '1':
                    k = j + 1
                    break

            if ying[i] != yang[j]:
                trans_count += 1

    trans_count = trans_count / 2

    # adjust for similarities in nonmatched characters

    # Main weight computation.
    weight = ((common_chars / <double>ying_length) +
              (common_chars / <double>yang_length) +
              (<double>(common_chars - trans_count) / <double>common_chars))
    weight = weight / 3

    # Continue to boost the weight if the strings are similar
    if winklerize and weight > 0.7:
        # Adjust for having up to the first 4 characters in common
        if min_length >= 4:
            j = 4
        else:
            j = min_length

        i = 0
        while i < j and ying[i] == yang[i] and _notnum(ying[i]):
            i += 1

        if i:
            weight += i * 0.1 * (1.0 - weight)


        # Optionally adjust for long strings. */
        # After agreeing beginning chars, at least two more must agree and
        # the agreeing characters must be > .5 of remaining characters.
        if (long_tolerance and min_length > 4 and common_chars > (i + 1) and
            (2 * common_chars) >= (min_length + i)):

            if _notnum(ying[0]):
                weight += (<double>(1.0 - weight) *
                           (<double>(common_chars - i - 1) /
                            <double>(ying_length + yang_length - i * 2 + 2)))

    free(ying_flag)
    free(yang_flag)

    return weight

def jaro_winkler(ying, yang):
    if not isinstance(ying, unicode):
        ying = tounicode(ying)
    if not isinstance(yang, unicode):
        yang = tounicode(yang)

    return _jaro_winkler(ying, yang, False, True)

def jaro_distance(ying, yang):
    if not isinstance(ying, unicode):
        ying = tounicode(ying)
    if not isinstance(yang, unicode):
        yang = tounicode(yang)

    return _jaro_winkler(ying, yang, False, False)