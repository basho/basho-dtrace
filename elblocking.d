/* -------------------------------------------------------------------
 *
 * elblocking.d: Show # of active Erlang schedulers in 10-second interval
 *
 * Copyright (c) 2012 Basho Technologies, Inc. All Rights Reserved.
 *
 * This file is provided to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file
 * except in compliance with the License.  You may obtain
 * a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 *
 * ------------------------------------------------------------------- */

/* General idea is to count the number of unique Erlang scheduler threads that
   schedule SOME work in a 10 second interval. If you have 64 schedulers, some
   portion of those should do SOMETHING in a 10 second interval, but a large
   number may be idle. If you see NO work being done, the call stack should give
   you an indicator of where to start looking and it suggests the VM is going to
   appear busy from the outside. */

BEGIN
{
    last_ts = timestamp;
}

profile-999hz
/$target == pid && arg1/
{
    @calls[uaddr(arg1)] = count();
}

pid$target::schedule:entry
/visible[tid] != last_ts/
{
    @scheduled = count();
    visible[tid] = last_ts;
}

tick-10sec
{
    last_ts = timestamp;
    setopt("aggsortrev", "true");
    printa("Number of active schedulers: %@8d\n", @scheduled);
    printf("Top calls:");
    trunc(@calls, 10);
    printa(@calls);
    clear(@calls);
    clear(@scheduled);
}

