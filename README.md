# idempotent_post

Intercept duplicate posts at the rack level, so clicking a button twice or anything
that would cause a post happening more than once won't create the object twice.
The basic idea is that the response was either lost or not waited for long enough,
therefore cache the response and return it whenever a duplicate post is sent.

This was extracted from another project and was dependent on Redis.

The plan is to extract the dependency on Redis and turn this into a gem.
