import path from "node:path";
import { fileURLToPath } from "node:url";
// By default, webpack bundles all Moment.js locales (in Moment.js 2.18.1,
// that’s 160 minified KBs).
// To strip unnecessary locales and bundle only the used ones,
// add moment-locales-webpack-plugin:
import MomentLocalesPlugin from 'moment-locales-webpack-plugin';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);


export default {
    entry: {
        wega: "./resources/js/init.js",
        swagger: "./resources/js/swagger.js",
    },
    output: {
        filename: "[name].js",
        //filename: "wega.js",
        //filename: (pathData) =>
        //    pathData.chunk.name === "init" ? "wega.js" : "[name].js",
        path: path.resolve(__dirname, "dist/resources/js"),
    },
    mode: 'development',
    plugins: [
        new MomentLocalesPlugin({
            localesToKeep: ['de', 'en'],
        }),
    ],
};
