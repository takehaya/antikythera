#include <stdio.h>

void bsort(int *base, int n) {
  for (int end = n - 1; end > 0; --end) {
    for (int i = 0; i < end; ++i) {
      if (base[i + 1] < base[i]) {
        int tmp = base[i];
        base[i] = base[i + 1];
        base[i + 1] = tmp;
      }
    }
  }
}

int main(void) {
  int arr[] = {7, 1, 4, 9, 3, 8, 2, 6, 5, 0};
  int len = sizeof(arr) / sizeof(arr[0]);

  bsort(arr, len);

  // debug output
  for (int i = 0; i < len; ++i) {
    printf("%d ", arr[i]);
  }
  putchar('\n');
  return 0;
}
