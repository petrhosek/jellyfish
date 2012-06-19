#include "jellyfish.h"
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

int levenshtein_distance(const char *s1, size_t len1, const char *s2, size_t len2)
{
    int i, j, n;
    int *r, *p1, *p2;
    int x1, x2;
    const char *tmp;

    /* strip common prefix */
    while (len1 > 0 && len2 > 0 && *s1 == *s2) {
        len1--;
        len2--;
        s1++; s2++;
    }

    /* strip common suffix */
    while (len1 > 0 && len2 > 0 && s1[len1 - 1] == s2[len2 - 1]) {
        len1--;
        len2--;
    }

    /* catch trivial cases */
    if (len1 == 0) return len2;
    if (len2 == 0) return len1;

    /* swap if s2 longer than s1 */
    if (len1 < len2)
    {
        tmp = s1; s1 = s2; s2 = tmp;
        len1 ^= len2; len2 ^= len1; len1 ^= len2;
    }

    /* fill initial row */
    n = (*s1 != *s2) ? 1 : 0;
    r = (int *)malloc(sizeof(int) * (len1 + 1));
    for (i = 0, p1 = r; i <= len1; *p1++ = i++);

    /* calculate columnwise */
    for (j = 1; j <= len2; ++j) {
        x2 = r[0] + 1;
        x1 = j;
        /* process ljne */
        r[0] = j;
        for (i = 1; i <= len1; ++i) {
            x2 -= s1[i - 1] == s2[j - 1];
            if (++x1 > x2) {
                x1 = x2;
            }
            x2 = r[i] + 1;
            if (x1 > x2) {
                x1 = x2;
            }
            r[i] = x1;
        }
    }

    /* total edit distance */
    n = r[len1];

    /* dispose the allocated memory */
    free(r);

    /* return result */
    return n;
}
