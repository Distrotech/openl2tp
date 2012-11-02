/*****************************************************************************
 * 
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2.1 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library; if not, write to the Free
 *  Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA
 *
 *****************************************************************************/

#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netdb.h>

/* Resolve hostname or ipaddr into struct in_addr.
 * Returns 1 on success, 0 on failure. 
 */
int cli_resolveip(const char *val, struct in_addr *ip)
{
	int code;
	struct addrinfo *res;

	code = getaddrinfo(val, NULL, NULL, &res);
	if (code) {
		printf("Failed to resolve address '%s': %s\n", val, gai_strerror(code));
		return 0;
	}

	/* use the first ip address available,
	 * save it inside provided in_addr structure.
	 */
	ip->s_addr = ((struct sockaddr_in*)(res->ai_addr))->sin_addr.s_addr;

	freeaddrinfo(res);
	return 1;
}

