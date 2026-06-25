// Copyright 2026 The Gitea Authors. All rights reserved.
// SPDX-License-Identifier: MIT

package misc

import (
	"net/http"
	"time"

	"gitea.dev/modules/structs"
	"gitea.dev/services/context"
)

// serverStartTime captures the moment this package is initialised so
// MiscHealth can report a monotonically increasing uptime since the
// server process started accepting requests.
var serverStartTime = time.Now()

// Health returns a basic liveness probe for the Gitea API.
func Health(ctx *context.APIContext) {
	// swagger:operation GET /misc/health miscellaneous getMiscHealth
	// ---
	// summary: Returns a basic liveness probe and process uptime
	// produces:
	// - application/json
	// responses:
	//   "200":
	//     "$ref": "#/responses/MiscHealth"
	ctx.JSON(http.StatusOK, &structs.MiscHealth{
		Status:        "ok",
		UptimeSeconds: int64(time.Since(serverStartTime).Seconds()),
	})
}
