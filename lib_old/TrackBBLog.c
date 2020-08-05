/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 2.
 *
 * SPDX-License-Identifier: (GPL-2.0)
 **/

#include "../header/TrackBBLog.h"
#include <stdio.h>
#include <string.h>

const char *trackbb_log_file = "track_bb_log.st";

TRACK_BB_ROW trackbb_new_row(unsigned line, const char *function_name) {
  TRACK_BB_ROW row;
  strncpy(row.function_name, function_name, FUNCTION_MAX_LENGTH_NAME);
  row.line = line;

  return row;
}

Bool is_in_tracked(unsigned line, MAP2CHECK_CONTAINER *log) {
  int i = log->size - 1;
  for (; i >= 0; i--) {
    TRACK_BB_ROW *row = (TRACK_BB_ROW *)get_element_at(i, *log);
    unsigned lineN = row->line;
    if (lineN == line) {
      return TRUE;
    }
  }
  return FALSE;
}

void trackbb_log_to_file(MAP2CHECK_CONTAINER *list) {
  FILE *output = fopen(trackbb_log_file, "w");
  int i = 0;
  for (; i < list->size; i++) {
    TRACK_BB_ROW *row = (TRACK_BB_ROW *)get_element_at(i, *list);
    fprintf(output, "%u;", row->line);
    fprintf(output, "%s\n", row->function_name);
  }
  fclose(output);
}
