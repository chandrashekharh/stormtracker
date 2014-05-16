<div id="table-of-contents">
<h2>Table of Contents</h2>
<div id="text-table-of-contents">
<ul>
<li><a href="#sec-1">1. StormTracker</a></li>
<li><a href="#sec-2">2. List of Stormtracker APIs</a>
<ul>
<li>
<ul>
<li><a href="#sec-2-0-1">2.0.1. POST <code>/agents</code></a></li>
<li><a href="#sec-2-0-2">2.0.2. POST  <code>/agents/:id/csr</code></a></li>
<li><a href="#sec-2-0-3">2.0.3. PUT    <code>/agents/:id</code></a></li>
<li><a href="#sec-2-0-4">2.0.4. PUT    <code>/agents/:id/status/:status</code></a></li>
<li><a href="#sec-2-0-5">2.0.5. GET     <code>/agents/:id/bolt</code></a></li>
<li><a href="#sec-2-0-6">2.0.6. GET     <code>/agents/serialKey/:key</code></a></li>
<li><a href="#sec-2-0-7">2.0.7. DELETE  <code>/agents/:id</code></a></li>
</ul>
</li>
</ul>
</li>
</ul>
</div>
</div>
# StormTracker

**Stormtracker** is the module which keeps track of all the stormflash endpoints - basically the one who provides identification, authorization and activation of stormflash endpoints

# List of Stormtracker APIs

<table border="2" cellspacing="0" cellpadding="6" rules="groups" frame="hsides">


<colgroup>
<col  class="left" />

<col  class="left" />

<col  class="left" />

<col  class="left" />
</colgroup>
<thead>
<tr>
<th scope="col" class="left">Verb</th>
<th scope="col" class="left">Uri</th>
<th scope="col" class="left">Description</th>
<th scope="col" class="left">Authorization</th>
</tr>
</thead>

<tbody>
<tr>
<td class="left">POST</td>
<td class="left">`/agents`</td>
<td class="left">Create an agent object</td>
<td class="left">No</td>
</tr>


<tr>
<td class="left">POST</td>
<td class="left">`/agents/:id/csr`</td>
<td class="left">Sign the incoming CSR, returns the cert</td>
<td class="left">Yes</td>
</tr>


<tr>
<td class="left">PUT</td>
<td class="left">`/agents/:id`</td>
<td class="left">Update the agent object</td>
<td class="left">Yes</td>
</tr>


<tr>
<td class="left">PUT</td>
<td class="left">`/agents/:id/status/:status`</td>
<td class="left">Update the state field in agent object</td>
<td class="left">No</td>
</tr>


<tr>
<td class="left">GET</td>
<td class="left">`/agents/:id`</td>
<td class="left">Retreive the agent</td>
<td class="left">Yes</td>
</tr>


<tr>
<td class="left">GET</td>
<td class="left">`/agents/:id/bolt`</td>
<td class="left">Retreive the underlying bolt object</td>
<td class="left">Yes</td>
</tr>


<tr>
<td class="left">GET</td>
<td class="left">`/agents/serialKey/:key`</td>
<td class="left">Retreive the agent by serial key</td>
<td class="left">Yes</td>
</tr>


<tr>
<td class="left">DELETE</td>
<td class="left">`/agents/:id`</td>
<td class="left">Remove the agent from db</td>
<td class="left">No</td>
</tr>
</tbody>
</table>



### POST `/agents`

Request JSON

	{
	  serialKey: "some serial key",
	  stoken: "some token"
	  password: "password",
	  stormbolt: {
		state: "ACTIVE",
		servers: ["bolt://testserver"],
		beacon: {
		  interval: 2000,
		  retry: 2000
		},
		loadbalance: {
		  algorithm: "roundrobin"
		}
	  }
	}

Response JSON

	{
	  id :"uuid"
	  serialKey: "some serial key",
	  stoken: "some token"
	  password: "password",
	  stormbolt: {
		state: "ACTIVE",
		servers: ["bolt://testserver"],
		beacon: {
		  interval: 2000,
		  retry: 2000
		},
		loadbalance: {
		  algorithm: "roundrobin"
		},
		cabundle: {
		  encoding: "base64",
		  data: "base64 encoded certificate"
		}
	  }
	}

### POST  `/agents/:id/csr`

Request JSON

	{
		encoding: "base64",
		data: "base64 encoded CSR"
	}

Response JSON

	{
		encoding: "base64",
		data: "base64 encoded signed certificate"
	}

### PUT    `/agents/:id`

Request JSON

	{
	  id:"uuid",
	  serialKey: "some serial key",
	  stoken: "some token"
	  password: "password",
	  stormbolt: {
		state: "ACTIVE",
		servers: ["bolt://testserver"],
		beacon: {
		  interval: 2000,
		  retry: 2000
		},
		loadbalance: {
		  algorithm: "roundrobin"
		}
	  }
	}

Response JSON

	{
	  id:"uuid",
	  serialKey: "some serial key",
	  stoken: "some token"
	  password: "password",
	  stormbolt: {
		state: "ACTIVE",
		servers: ["bolt://testserver"],
		beacon: {
		  interval: 2000,
		  retry: 2000
		},
		loadbalance: {
		  algorithm: "roundrobin"
		}
	  }
	}

### PUT    `/agents/:id/status/:status`

	Update the status valid values (ACTIVE | INACTIVE)
Returns Http Status code 204

GET     `/agents/:id`

Response JSON

	{
	  id :"uuid"
	  serialKey: "some serial key",
	  stoken: "some token"
	  password: "password",
	  stormbolt: {
		state: "ACTIVE",
		servers: ["bolt://testserver"],
		beacon: {
		  interval: 2000,
		  retry: 2000
		},
		loadbalance: {
		  algorithm: "roundrobin"
		},
		cabundle: {
		  encoding: "base64",
		  data: "base64 encoded certificate"
		}
	  }
	}

### GET     `/agents/:id/bolt`

Response JSON

	{
		state: "ACTIVE",
		servers: ["bolt://testserver"],
		beacon: {
		  interval: 2000,
		  retry: 2000
		},
		loadbalance: {
		  algorithm: "roundrobin"
		},
		cabundle: {
		  encoding: "base64",
		  data: "base64 encoded certificate"
		}
	}

### GET     `/agents/serialKey/:key`

Response JSON

	{
	  id :"uuid"
	  serialKey: "some serial key",
	  stoken: "some token"
	  password: "password",
	  stormbolt: {
		state: "ACTIVE",
		servers: ["bolt://testserver"],
		beacon: {
		  interval: 2000,
		  retry: 2000
		},
		loadbalance: {
		  algorithm: "roundrobin"
		},
		cabundle: {
		  encoding: "base64",
		  data: "base64 encoded certificate"
		}
	  }
	}

### DELETE  `/agents/:id`

Returns Http status code 204
