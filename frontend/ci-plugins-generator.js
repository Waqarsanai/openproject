const path = require('node:path');
const fs = require('node:fs');
const _ = require('lodash');

const LINKED_PLUGINS_MODULE_TEMPLATE = (plugins) => {
  const importableName = (name) => _.upperFirst(_.camelCase(name));
  const frontendPlugins = plugins.map(([name]) => [name, importableName(name)]);

  return `
import {NgModule} from "@angular/core";
${
  frontendPlugins
    .map(([actualName, moduleName]) =>
      `import {PluginModule as ${moduleName}} from './linked/${actualName}/main';`
    )
    .join('\n')
}

@NgModule({
    imports: [
        ${
          frontendPlugins
            .map(([, moduleName]) => moduleName)
            .join(`,\n${' '.repeat(8)}`)
        }
    ],
})
export class LinkedPluginsModule { }
  `;
};

const railsRoot = path.join(__dirname, '..');
const pluginDir = path.join(railsRoot, 'modules');
const targetDir = path.join(railsRoot, 'frontend/src/app/features/plugins/linked');

const plugins = new Map([
  ['budgets', path.join(pluginDir, 'budgets')],
  ['costs', path.join(pluginDir, 'costs')],
  ['openproject-avatars', path.join(pluginDir, 'avatars')],
  ['openproject-documents', path.join(pluginDir, 'documents')],
  ['openproject-github_integration', path.join(pluginDir, 'github_integration')],
  ['openproject-gitlab_integration', path.join(pluginDir, 'gitlab_integration')],
  ['openproject-meeting', path.join(pluginDir, 'meeting')]
]);

// determine which configured plugins actually have a frontend entry
const allFrontendPlugins = Array.from(plugins).filter(([name, pluginPath]) => {
  const frontendEntry = path.join(pluginPath, 'frontend', 'module', 'main.ts');
  return fs.existsSync(frontendEntry);
});

console.log(`Cleaning linked target directory ${targetDir}`);
fs.rmSync(targetDir, { recursive: true, force: true });
fs.mkdirSync(targetDir, { recursive: true });

const symlinkType = process.platform === 'win32' ? 'junction' : 'dir';

allFrontendPlugins.forEach(([name, pluginPath]) => {
  const linkTarget = path.join(pluginPath, 'frontend', 'module');
  const linkPath = path.join(targetDir, name);

  console.log(`Linking frontend of OpenProject plugin ${name} (${linkPath} -> ${linkTarget}).`);
  if (!fs.existsSync(linkTarget)) {
    console.warn(`Skipping ${name}: link target does not exist: ${linkTarget}`);
    return;
  }

  try {
    fs.symlinkSync(linkTarget, linkPath, symlinkType);
  } catch (err) {
    console.error(`Failed to create symlink for ${name}: ${err && err.message ? err.message : err}`);
  }
});

function generatePluginModule(plugins) {
  const fileRegister = path.join(railsRoot, 'frontend/src/app/features/plugins/linked-plugins.module.ts');
  console.log(`Regenerating frontend plugin registry ${fileRegister}.`);

  const result = LINKED_PLUGINS_MODULE_TEMPLATE(plugins);
  fs.writeFileSync(fileRegister, result);
}

generatePluginModule(allFrontendPlugins);
