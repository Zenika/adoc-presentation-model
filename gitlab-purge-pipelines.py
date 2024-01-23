#!/usr/local/bin/python
#
# Script deleting old pipelines
#
# WARNING: This does not delete artifacts on private GitLab instances, clean up orphans with
#    sudo gitlab-rake gitlab:cleanup:orphan_job_artifact_files DRY_RUN=false
#

# https://click.palletsprojects.com/en/7.x/
import click
# https://python-gitlab.readthedocs.io/en/stable/gl_objects/pipelines_and_jobs.html
# magic objects inside, preventing proper auto-completion :(
from gitlab import Gitlab


@click.command()
# GitLab server URL ($CI_SERVER_URL in pipelines)
@click.argument('server_url')
# Project unique ID ($CI_PROJECT_ID in pipelines)
@click.argument('project_id')
# Authentication token with delete right on pipelines
# At the end of parameters, to be explicit when it is missing, since the other ones are always there
@click.argument('token')
@click.option('--keep', '-k', default=30, help='Number of latest pipelines to keep (default 30)')
@click.option('--delete/--dry-run', default=True)
def purge_old_pipelines(server_url, project_id, token, keep, delete):

    project = Gitlab(server_url, private_token=token,
                     per_page=100).projects.get(project_id)
    pipelines = project.pipelines.list(iterator=True)
    print('\nKeeping only {} recent pipelines in project {}\n'.format(
        keep, project.name), flush=True)

    # 'list' is ordered, a 'set' would print deletion in random order
    old_pipeline_ids = list()
    count_pipe = 0

    # pipelines are iterated from newest to oldest
    for pipeline in pipelines:
        count_pipe += 1
        if count_pipe > keep:
            old_pipeline_ids.append(pipeline.id)

    for old_pipeline_id in old_pipeline_ids:
        pipeline = project.pipelines.get(old_pipeline_id)
        if delete:
            print(f'Deleting pipeline {pipeline.id}...', flush=True)
            pipeline.delete()
        else:
            print(
                f'[DRY RUN] Pipeline {pipeline.id} would be deleted...', flush=True)


if __name__ == '__main__':
    purge_old_pipelines()
