/**
 * Copyright (C) 2014 - 2020 Map2Check tool
 * This file is part of the Map2Check tool, and is made available under
 * the terms of the GNU General Public License version 2.
 *
 * SPDX-License-Identifier: (GPL-2.0)
 **/

/**********************************************************************
 * This file contains all methods that are used for the AllocationLog  *
 * which is a structure that contains all memory operations            *
 ***********************************************************************/
#include "Container.h"
#include "Map2CheckTypes.h"

#ifndef AllocationLog_H
#define AllocationLog_H

/**
 * Mark element as not free to a MAP2CHECK_CONTAINER
 * @param  allocation_log Pointer to the MAP2CHECK_CONTAINER
 * @param  address        Memory Address to be added
 * @return                Returns success of operation
 */
Bool mark_allocation_log(MAP2CHECK_CONTAINER *allocation_log, long address);

/**
 * Mark element as free to a MAP2CHECK_CONTAINER
 * @param  allocation_log Pointer to the MAP2CHECK_CONTAINER
 * @param  address        Memory Address to be freed
 * @return                Returns success of operation
 */
Bool mark_deallocation_log(MAP2CHECK_CONTAINER *allocation_log, long address);

/**
 * @deprecated
 * @brief Checks if an address exists in a MAP2CHECK_CONTAINER, it checks from
 * the last added to the first
 * @param  allocation_log Pointer to the MAP2CHECK_CONTAINER
 * @param  address        Memory Address to be checked
 * @return                Returns the most recent status of the address
 */
enum MemoryAddressStatus
check_address_allocation_log(MAP2CHECK_CONTAINER *allocation_log, long address);

// void print_allocation_log(MAP2CHECK_CONTAINER* allocation_log);

/**
 * This method initializes a MEMORY_ALLOCATIONS_ROW with the defined parameters
 * @param  address Memory Address to be logged
 * @param  is_free Is the *address* released?
 * @return         Returns the initialized MEMORY_ALLOCATIONS_ROW
 */
MEMORY_ALLOCATIONS_ROW new_memory_row(long address, Bool is_free);

MEMORY_ALLOCATIONS_ROW *
find_row_with_address(MAP2CHECK_CONTAINER *allocation_log, void *ptr);

/**
 * Checks if the address is a valid address
 * @param allocation_log  Address to a allocation log
 * @param address         Address to be validated
 * @param last_address    Extra variable to get the last address of the memory
 * space
 * @return A bool representing if address is valid
 */
Bool is_valid_allocation_address(MAP2CHECK_CONTAINER *allocation_log,
                                 void *address, int size_to_destiny);

void allocation_log_to_file(MAP2CHECK_CONTAINER *list);
/**
 * Checks if all addresses of allocation log where deallocated
 * @param allocation_log  Address to a allocation log
 * @return A long for leaked address (0 if none)
 */
long valid_allocation_log(MAP2CHECK_CONTAINER *allocation_log);

#endif
