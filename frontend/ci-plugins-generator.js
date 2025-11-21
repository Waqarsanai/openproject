const path = require('node:path');
const fs = require('node:fs');
const _ = require('lodash');

// Allow safe execution for local testing without modifying repository files.
const DRY_RUN = (process.env.DRY_RUN === '1' || process.env.DRY_RUN === 'true');

const railsRoot = path.resolve(__dirname, '..');
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

function linkedPluginsModuleTemplate(pluginsList) {
  const importableName = (name) => _.upperFirst(_.camelCase(name));
  const frontendPlugins = pluginsList.map(([name]) => [name, importableName(name)]);

  const imports = frontendPlugins
    .map(([actualName, moduleName]) => `import {PluginModule as ${moduleName}} from './linked/${actualName}/main';`)
    .join('\n');

  const moduleList = frontendPlugins.map(([, moduleName]) => moduleName).join(',\n        ');

  return (`import {NgModule} from "@angular/core";\n\n${imports}\n\n@NgModule({\n    imports: [\n        ${moduleList}\n    ],\n})\nexport class LinkedPluginsModule { }\n`).trim() + '\n';
}

function collectFrontendPlugins(pluginsMap) {
  return Array.from(pluginsMap).filter(([name, pluginPath]) => {
    const frontendEntry = path.join(pluginPath, 'frontend', 'module', 'main.ts');
    return fs.existsSync(frontendEntry);
  });
}

function ensureTargetDirectory(dir) {
  console.info(`Preparing linked plugins target directory: ${dir}`);
  if (DRY_RUN) {
    console.info('[DRY_RUN] Would remove and recreate target directory');
    return;
  }

  try {
    if (fs.existsSync(dir)) {
      fs.rmSync(dir, { recursive: true, force: true });
    }
    fs.mkdirSync(dir, { recursive: true });
  } catch (err) {
    throw new Error(`Failed to prepare target directory ${dir}: ${err && err.message ? err.message : err}`);
  }
}

function linkPluginsToTarget(pluginsList, dir) {
  const symlinkType = process.platform === 'win32' ? 'junction' : 'dir';

  for (const [name, pluginPath] of pluginsList) {
    const linkTarget = path.join(pluginPath, 'frontend', 'module');
    const linkPath = path.join(dir, name);

    console.info(`Linking plugin ${name}: ${path.relative(railsRoot, linkPath)} -> ${path.relative(railsRoot, linkTarget)}`);

    if (!fs.existsSync(linkTarget)) {
      console.warn(`Skipping ${name}: link target does not exist: ${linkTarget}`);
      continue;
    }

    if (DRY_RUN) {
      console.info(`[DRY_RUN] Would create symlink: ${linkPath} -> ${linkTarget} (type: ${symlinkType})`);
      continue;
    }

    try {
      fs.symlinkSync(linkTarget, linkPath, symlinkType);
    } catch (err) {
      // If link exists, try to remove and recreate
      if (err && err.code === 'EEXIST') {
        try {
          fs.rmSync(linkPath, { recursive: true, force: true });
          fs.symlinkSync(linkTarget, linkPath, symlinkType);
        } catch (err2) {
          console.error(`Failed to recreate symlink for ${name}: ${err2 && err2.message ? err2.message : err2}`);
        }
      } else {
        console.error(`Failed to create symlink for ${name}: ${err && err.message ? err.message : err}`);
      }
    }
  }
}

function generatePluginModule(pluginsList) {
  const fileRegister = path.join(railsRoot, 'frontend/src/app/features/plugins/linked-plugins.module.ts');
  console.info(`Regenerating frontend plugin registry: ${fileRegister}`);

  const result = linkedPluginsModuleTemplate(pluginsList);

  if (DRY_RUN) {
    console.info('[DRY_RUN] Would write generated module with content:\n' + result);
    return;
  }

  try {
    fs.writeFileSync(fileRegister, result, { encoding: 'utf8' });
  } catch (err) {
    throw new Error(`Failed to write plugin registry ${fileRegister}: ${err && err.message ? err.message : err}`);
  }
}

function main() {
  try {
    const allFrontendPlugins = collectFrontendPlugins(plugins);

    ensureTargetDirectory(targetDir);
    linkPluginsToTarget(allFrontendPlugins, targetDir);
    generatePluginModule(allFrontendPlugins);

    console.info('ci-plugins-generator: finished successfully');
  } catch (err) {
    console.error('ci-plugins-generator: error', err && err.message ? err.message : err);
    process.exitCode = 1;
  }
}

main();
