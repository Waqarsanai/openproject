import { I18nService } from 'core-app/core/i18n/i18n.service';
import {
  ChangeDetectionStrategy,
  ChangeDetectorRef,
  Component,
  ElementRef,
  EventEmitter,
  HostBinding,
  Input,
  OnChanges,
  OnInit,
  Output,
  SimpleChanges,
} from '@angular/core';
import {
  SearchableProjectListService,
} from 'core-app/shared/components/searchable-project-list/searchable-project-list.service';
import { IProjectData } from 'core-app/shared/components/searchable-project-list/project-data';
import { PathHelperService } from 'core-app/core/path-helper/path-helper.service';
import { ConfigurationService } from 'core-app/core/config/configuration.service';
import { CurrentProjectService } from 'core-app/core/current-project/current-project.service';
import {
  toDOMString,
  versionsIconData,
  briefcaseIconData,
  SVGData,
} from '@openproject/octicons-angular';
import { DomSanitizer, SafeHtml } from '@angular/platform-browser';

@Component({
  selector: '[op-header-project-select-list]',
  changeDetection: ChangeDetectionStrategy.OnPush,
  templateUrl: './header-project-select-list.component.html',
  styleUrls: ['./header-project-select-list.component.sass'],
  standalone: false,
})
export class OpHeaderProjectSelectListComponent implements OnInit, OnChanges {
  @HostBinding('class.spot-list') classNameList = true;

  @HostBinding('class.op-header-project-select-list') className = true;

  @Output() update = new EventEmitter<string[]>();

  @Input() @HostBinding('class.op-header-project-select-list--root') root = false;

  @Input() projects:IProjectData[] = [];

  @Input() favored:string[] = [];

  @Input() displayMode:string;

  @Input() searchText = '';

  public filteredProjects:IProjectData[];

  public text = {
    does_not_match_search: this.I18n.t('js.include_projects.tooltip.does_not_match_search'),
    include_all_selected: this.I18n.t('js.include_projects.tooltip.include_all_selected'),
  };

  public portfolioModelsEnabled = this.configuration.activeFeatureFlags.includes('portfolioModels');

  constructor(
    readonly I18n:I18nService,
    readonly pathHelper:PathHelperService,
    readonly configuration:ConfigurationService,
    readonly searchableProjectListService:SearchableProjectListService,
    readonly elementRef:ElementRef,
    readonly cdRef:ChangeDetectorRef,
    readonly currentProjectService:CurrentProjectService,
    readonly sanitizer:DomSanitizer
  ) { }

  ngOnInit():void {
    if (this.root) {
      this.searchableProjectListService.selectedItemID$.subscribe((selectedItemID) => {
        // We have to push this back once so the component gets time to render the list
        // and we can actually find the element and scroll to it.
        requestAnimationFrame(() => {
          const itemAction = (this.elementRef.nativeElement as HTMLElement)
            .querySelectorAll(`.spot-list--item-action[data-project-id="${selectedItemID ?? ''}"]`);
          itemAction[0]?.scrollIntoView();
        });
      });
    }

    this.updateProjectFilter();
  }

  ngOnChanges(changes:SimpleChanges) {
    if (changes.displayMode || changes.projects || changes.favored) {
      this.updateProjectFilter();
    }
  }

  updateProjectFilter() {
    this.filteredProjects = this.projects.filter((project) => {
      if (this.displayMode === 'all') {
        return true;
      }

      return this.showWhenFavored(project);
    });
  }

  showWhenFavored(project:IProjectData):boolean {
    if (this.isFavored(project)) {
      return true;
    }

    return project.children.length > 0 && project.children.some((child) => this.showWhenFavored(child));
  }

  isFavored(project:IProjectData):boolean {
    return this.favored.includes(project.id.toString());
  }

  extendedUrl(projectId:string|null):string {
    const currentMenuItem = document.querySelector('meta[name="current_menu_item"]') as HTMLMetaElement|undefined;
    const url = projectId === null ? window.appBasePath : this.pathHelper.projectPath(projectId);

    if (!currentMenuItem) {
      return url;
    }

    return `${url}?jump=${encodeURIComponent(currentMenuItem.content)}`;
  }

  workspaceTypeIconWithLabel(project:IProjectData):SafeHtml {
    const iconData = this.workspaceTypeSVGData(project.workspaceType);
    if (!iconData) {
      return '';
    }

    const htmlString = toDOMString(iconData, 'small', { 'aria-hidden': 'true', class: 'octicon' });
    const translatedTypeName = this.I18n.t(`js.include_workspaces.types.${project.workspaceType}`);
    const iconWithText = htmlString + ' ' + translatedTypeName;
    return this.sanitizer.bypassSecurityTrustHtml(iconWithText);
  }

  private workspaceTypeSVGData(workspaceType:string):SVGData|undefined{
    switch (workspaceType) {
      case 'program': {
        return versionsIconData;
      }
      case 'portfolio': {
        return briefcaseIconData;
      }
      default: {
        return undefined; // Case fallthrough for eslint
      }
    }
  }
}
