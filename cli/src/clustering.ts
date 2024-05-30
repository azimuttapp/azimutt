import chalk from "chalk";
import {distinct, Logger, pluralizeL, removeUndefined, splitWords} from "@azimutt/utils"
import {Connector, getEntities, DatabaseQuery, DatabaseUrlParsed, EntityId, parseDatabaseUrl, QueryId} from "@azimutt/models"
import {getConnector, track} from "@azimutt/gateway"
import {version} from "./version.js";
import {fileWrite} from "./utils/file.js";
import {loggerNoOp} from "./utils/logger.js";

export type Opts = {}

export async function launchClustering(url: string, opts: Opts, logger: Logger): Promise<void> {
    const dbUrl: DatabaseUrlParsed = parseDatabaseUrl(url)
    const connector: Connector | undefined = getConnector(dbUrl)
    if (!connector) return Promise.reject(`Invalid connector for ${dbUrl.kind ? `${dbUrl.kind} db` : `unknown db (${dbUrl.full})`}`)

    const app = 'azimutt-cli-clustering'
    const queries: DatabaseQuery[] = await connector.getQueryHistory(app, dbUrl, {logger: loggerNoOp, database: dbUrl.db}).catch(err => {
        if (typeof err === 'string' && err === 'Not implemented') logger.log(chalk.blue(`Query history is not supported yet on ${dbUrl.kind}, ping us ;)`))
        if (typeof err === 'object' && 'message' in err && err.message.indexOf('"pg_stat_statements" does not exist')) logger.log(chalk.blue(`Can't get query history as pg_stat_statements is not enabled. Enable it for a better db analysis.`))
        return []
    })
    const selectQueries = queries.filter(q => q.query.trim().toLowerCase().startsWith('select '))
    const selectJoinQueries = selectQueries.map(query => ({query, entities: getEntities(query.query)})).filter(q => q.entities.length > 1)
    track('cli__clustering__run', removeUndefined({version, database: dbUrl.kind, nb_queries: queries.length, nb_select_join: selectJoinQueries.length}), 'cli').then(() => {})

    const links: Record<EntityId, Record<EntityId, QueryId[]>> = {}
    selectJoinQueries.forEach(({query, entities}) => {
            const [main, ...joins] = distinct(entities.map(e => e.entity))
            if (!links[main]) links[main] = {}
            joins.forEach(join => {
                if (!links[main][join]) {
                    links[main][join] = [query.id]
                } else {
                    links[main][join].push(query.id)
                }
            })
    })

    logger.log(`Found ${pluralizeL(queries, 'query')}, ${selectQueries.length} SELECTs and ${selectJoinQueries.length} JOINs.`)
    const path = 'clustering.html'
    await fileWrite(path, buildGraph(links))
    logger.log(`Graph written in ${path}, open it to see the result`)
}

type GraphNode = {id: string, prefix: string}
type GraphLink = {source: string, target: string, strength: number}
function buildGraph(data: Record<EntityId, Record<EntityId, QueryId[]>>): string {
    const nodes: GraphNode[] = [...new Set(Object.entries(data).flatMap(([k, v]) => [k, ...Object.keys(v)]))]
        .map(e => ({id: e, prefix: splitWords(e)[0]}))
    const links: GraphLink[] = Object.entries(data).flatMap(([source, targets]) =>
        Object.entries(targets).map(([target, queries]) =>
            ({source, target, strength: queries.length})
        )
    )
    const maxStrength = Math.max(...links.map(l => l.strength))
    // https://vasturiano.github.io/3d-force-graph
    return `<head>
  <style>body { margin: 0; }</style>
  <script src="https://unpkg.com/3d-force-graph"></script>
</head>
<body>
  <div id="3d-graph"></div>
  <script type="importmap">{ "imports": { "three": "https://unpkg.com/three/build/three.module.js" }}</script>
  <script type="module">
    import SpriteText from "https://unpkg.com/three-spritetext/dist/three-spritetext.mjs";
    const Graph = ForceGraph3D({ controlType: 'orbit' })(document.getElementById('3d-graph'))
      .graphData({
        nodes: ${JSON.stringify(nodes, null, 2)},
        links: ${JSON.stringify(links, null, 2)}
      })
      .numDimensions(3) // make it 3D
      .nodeLabel('id')
      .nodeAutoColorBy('prefix')
      .linkDirectionalArrowLength(3.5) // size of the link arrow
      .linkDirectionalArrowRelPos(1) // position of the arrow on the link (0-1)
      .linkCurvature(0.25)
      .linkDirectionalParticles("strength")
      .linkDirectionalParticleSpeed(d => 0.01)
      // link label
      .linkThreeObjectExtend(true)
      .linkThreeObject(link => {
        // extend link with text sprite
        const sprite = new SpriteText(link.source +' > ' + link.target + ' (' + link.strength + ')');
        sprite.color = 'lightgrey';
        sprite.textHeight = 2;
        return sprite;
      })
      .linkPositionUpdate((sprite, { start, end }) => {
        const middlePos = Object.assign(...['x', 'y', 'z'].map(c => ({
          [c]: start[c] + (end[c] - start[c]) / 2 // calc middle point
        })));

        // Position sprite
        Object.assign(sprite.position, middlePos);
      })
      .onNodeDragEnd(node => {
        node.fx = node.x;
        node.fy = node.y;
        node.fz = node.z;
      })
      .onNodeClick(node => {
        // Aim at node from outside it
        const distance = 150;
        const distRatio = 1 + distance/Math.hypot(node.x, node.y, node.z);

        const newPos = node.x || node.y || node.z
            ? { x: node.x * distRatio, y: node.y * distRatio, z: node.z * distRatio }
            : { x: 0, y: 0, z: distance }; // special case if node is in (0,0,0)

        Graph.cameraPosition(
          newPos, // new position
          node, // lookAt ({ x, y, z })
          3000  // ms transition duration
        );
      });

    Graph.d3Force('link').distance(link => Math.round(10 * 7 / link.strength));
  </script>
</body>
`
}
