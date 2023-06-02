import {configFromEnv} from "./plugins/config"
import {startServer} from "./server"

export default startServer(configFromEnv())
