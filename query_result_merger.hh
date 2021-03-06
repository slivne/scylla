/*
 * Copyright 2015 Cloudius Systems
 */

/*
 * This file is part of Scylla.
 *
 * Scylla is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Scylla is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Scylla.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma once

#include "core/distributed.hh"
#include "query-result.hh"

namespace query {

// Merges non-overlapping results into one
// Implements @Reducer concept from distributed.hh
class result_merger {
    std::vector<foreign_ptr<lw_shared_ptr<query::result>>> _partial;
public:
    void reserve(size_t size) {
        _partial.reserve(size);
    }

    void operator()(foreign_ptr<lw_shared_ptr<query::result>> r) {
        _partial.emplace_back(std::move(r));
    }

    // FIXME: Eventually we should return a composite_query_result here
    // which holds the vector of query results and which can be quickly turned
    // into packet fragments by the transport layer without copying the data.
    foreign_ptr<lw_shared_ptr<query::result>> get();
};

}
