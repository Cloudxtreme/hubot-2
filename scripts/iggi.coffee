r = require "rethinkdb"
randomstring = require "randomstring"
https = require "https"

module.exports = (robot) ->
    robot.logger.error "connecting to rethinkdb from iggi"
    r.connect
        host: process.env.RETHINKDB_PORT_28015_TCP_ADDR and process.env.RETHINKDB_PORT_28015_TCP_ADDR or "127.0.0.1"
        port: 28015
        authKey: process.env.RETHINKDB_AUTHKEY and process.env.RETHINKDB_AUTHKEY or null
    , (error, conn) ->
        if error
            robot.logger.error error
            return

        verify = (msg) ->
            id = randomstring.generate 20
            date = new Date()

            invite =
                id: id
                source: "lavabroom"
                created_at: date

            r.db("invite").table("invites").insert(invite).run conn, (error, result) ->
                if error
                    msg.reply "Database error: " + error
                    return

                msg.reply "New invitation: https://invite.lavaboom.com/#/" + invite.id
                return

        verifym = (msg) ->
            perk = undefined
            count = 0

            switch msg.match[1]
                when "sue"
                    perk = "Supporter (EB)"
                    count = 1
                when "su"
                    perk = "Supporter"
                    count = 1
                when "su3"
                    perk = "Supporter III"
                    count = 3
                when "spe"
                    perk = "Supporter Premium (EB)"
                    count = 1
                when "sup"
                    perk = "Supporter Premium"
                    count = 1
                when "suc"
                    perk = "Supporter Chic"
                    count = 6
                when "sul"
                    perk = "Supporter Premium - Lovebirds"
                    count = 2
                when "sux"
                    perk = "Supporter X"
                    count = 7
                when "dee"
                    perk = "Developer (EB)"
                    count = 7
                when "spf"
                    perk = "Supporter Premium - Family"
                    count = 5
                when "de"
                    perk = "Developer"
                    count = 7
                when "dep"
                    perk = "Developer Plus"
                    count = 14
                when "deu"
                    perk = "Developer Ultimate"
                    count = 14
                when "spl"
                    perk = "Supporter Premium - Lifetime"
                    count = 1

            accounts = []
            invites  = []
            links    = []
            date     = new Date()

            if count > 1
                for [1..count]
                    invite_id  = randomstring.generate 20

                    invites.push
                        id:         invite_id
                        source:     "lavabroom"
                        created_at: date

                    links.push "https://invite.lavaboom.com/#/" + invite_id
            else
                invite_id  = randomstring.generate 20
                #account_id = randomstring.generate 20

                #accounts.push
                #    id:        account_id
                #    alt_email: msg.match[2]
                #    status:    "registered"
                #    type:      "supporter"

                invites.push
                    id:         invite_id
                    source:     "lavabroom"
                    created_at: date
                    #account_id: account_id

                links.push "https://invite.lavaboom.com/#/" + invite_id

            r.db("prod").table("accounts").insert(accounts).run conn, (error, cursor) ->
                if error
                    msg.reply "Database error #1: " + error
                    return

                r.db("invite").table("invites").insert(invites).run conn, (error, result) ->
                    if error
                        msg.reply "Database error #2: " + error
                        return

                    email = """Dear supporter

Thank you for your contribution! By helping us you’re bringing our vision of secure email for everyone closer to reality.
You’ve selected #{perk}, #{if links.length > 1 then 'here are your invite tokens' else 'here’s your invite token'}:

#{links.join('\n')}

Click #{if links.length > 1 then 'one of the links above' else 'the link above'} to start the registration process.

You’re getting instant access to Lavaboom beta, a supporter account that has 2GB free for life and early access to Lavaboom features. 

Feel free to report any eventual bugs to http://web.lava.wtf, and if you lose your invite token or you’d like to use it on an existing account or username reservation, please email us at hello@lavaboom.com and we’ll regenerate it.

Best wishes,
Lavaboom team

PS: Share this with your friends and family to help make the Internet a more secure place!"""

                    req = https.request
                        hostname: "api.lavaboom.com"
                        port:     443
                        path:     "/emails"
                        method:   "POST"
                        headers:
                            "Authorization": "Bearer NH1IL4PwB1PXWAzrt0ka"
                            "Content-Type":  "application/json"
                    , (res) ->
                        msg.reply count + " invitations sent to " + msg.match[2]

                        #res.on "data", (chunk) ->
                        #    msg.reply chunk
                    
                    req.write JSON.stringify
                        kind:         "raw"
                        to:           [msg.match[2]]
                        body:         email
                        from:         "Lavaboom Team <hello@lavaboom.com>"
                        subject:      "Thank you for your contribution!"
                        content_type: "text/plain"

                    req.end()

        robot.respond /iggi$/i, verify
        robot.respond /iggim (\w*) (\S*)/i, verifym
